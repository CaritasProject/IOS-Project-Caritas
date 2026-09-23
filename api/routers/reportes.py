import calendar
from datetime import date

import pyodbc
from flask import Blueprint, jsonify, request
from pydantic import ValidationError

from core.db import obtener_conexion
from models.reporte import ConfiguracionReporte

bp = Blueprint("reportes", __name__, url_prefix="/reportes")

TIPO_PARA_APP = {"INGRESOS": "Ingresos", "COBRANZA": "Cobranza",
                 "TELEMARKETING": "Telemarketing", "METAS": "Metas"}
FORMATO_PARA_APP = {"PDF": "PDF", "EXCEL": "Excel", "CSV": "CSV"}

NOMBRE_BASE = {"INGRESOS": "Ingresos", "COBRANZA": "Cobranza",
               "TELEMARKETING": "Telemarketing", "METAS": "Avance de metas"}
NOMBRE_SEMANAL = {"INGRESOS": "Ingresos semanales", "COBRANZA": "Cobranza semanal",
                  "TELEMARKETING": "Telemarketing semanal", "METAS": "Avance de metas semanal"}
NOMBRE_MENSUAL = {"INGRESOS": "Ingresos mensuales", "COBRANZA": "Cobranza mensual",
                  "TELEMARKETING": "Telemarketing mensual", "METAS": "Avance de metas mensual"}

MESES_CORTOS = ["ene", "feb", "mar", "abr", "may", "jun",
                "jul", "ago", "sep", "oct", "nov", "dic"]
MESES_LARGOS = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
                "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
TRIMESTRES = ["primer", "segundo", "tercer", "cuarto"]

CONSULTA_REPORTES = """
SELECT h.ID_REPORTE, t.NOMBRE AS TIPO_REPORTE, h.FECHA_DESDE, h.FECHA_HASTA,
       f.NOMBRE AS FORMATO, h.FECHA_GENERACION, m.COMPROMETIDO, m.COBRADO
FROM dbo.HISTORIAL_REPORTE h
JOIN dbo.CAT_TIPO_REPORTE t    ON t.ID_TIPO_REPORTE = h.ID_TIPO_REPORTE
JOIN dbo.CAT_FORMATO_REPORTE f ON f.ID_FORMATO = h.ID_FORMATO
CROSS APPLY (
    SELECT ISNULL(SUM(b.IMPORTE), 0)         AS COMPROMETIDO,
           ISNULL(SUM(b.IMPORTE_COBRADO), 0) AS COBRADO
    FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
    JOIN dbo.OPE_DONATIVOS_DONANTE d ON d.ID_DONATIVO = b.ID_DONATIVO
    WHERE b.FECHA_COBRO BETWEEN h.FECHA_DESDE AND h.FECHA_HASTA
      AND (NOT EXISTS (SELECT 1 FROM dbo.REPORTE_LINEA_ESTRATEGICA al WHERE al.ID_REPORTE = h.ID_REPORTE)
           OR d.ID_LINEA_ESTRATEGICA IN (SELECT al.ID_LINEA_ESTRATEGICA FROM dbo.REPORTE_LINEA_ESTRATEGICA al
                                         WHERE al.ID_REPORTE = h.ID_REPORTE))
      AND (NOT EXISTS (SELECT 1 FROM dbo.REPORTE_CAMPANA_FINANCIERA ac WHERE ac.ID_REPORTE = h.ID_REPORTE)
           OR d.ID_CAMPANA_FINANCIERA IN (SELECT ac.ID_CAMPANA_FINANCIERA FROM dbo.REPORTE_CAMPANA_FINANCIERA ac
                                          WHERE ac.ID_REPORTE = h.ID_REPORTE))
) m
"""


def error(mensaje: str, codigo: int):
    return jsonify({"error": mensaje}), codigo


def es_mes_completo(desde: date, hasta: date) -> bool:
    ultimo_dia = calendar.monthrange(desde.year, desde.month)[1]
    return desde.day == 1 and hasta == date(desde.year, desde.month, ultimo_dia)


def es_trimestre_completo(desde: date, hasta: date) -> bool:
    if desde.day != 1 or desde.month not in (1, 4, 7, 10):
        return False
    mes_final = desde.month + 2
    ultimo_dia = calendar.monthrange(desde.year, mes_final)[1]
    return hasta == date(desde.year, mes_final, ultimo_dia)


def nombre_del_reporte(tipo: str, desde: date, hasta: date) -> str:
    dias = (hasta - desde).days + 1
    if dias <= 7:
        return f"{NOMBRE_SEMANAL[tipo]} · sem {desde.isocalendar().week}"
    if es_mes_completo(desde, hasta):
        return f"{NOMBRE_MENSUAL[tipo]} · {MESES_LARGOS[desde.month - 1]}"
    if es_trimestre_completo(desde, hasta):
        return f"{NOMBRE_BASE[tipo]} · {TRIMESTRES[(desde.month - 1) // 3]} trimestre"
    return f"{NOMBRE_BASE[tipo]} · {rango_corto(desde, hasta)}"


def rango_corto(desde: date, hasta: date) -> str:
    if (desde.year, desde.month) == (hasta.year, hasta.month):
        return f"{desde.day}–{hasta.day} {MESES_CORTOS[desde.month - 1]}"
    return (f"{desde.day} {MESES_CORTOS[desde.month - 1]} – "
            f"{hasta.day} {MESES_CORTOS[hasta.month - 1]}")


def fila_a_json(fila) -> dict:
    tipo, desde, hasta = fila.TIPO_REPORTE, fila.FECHA_DESDE, fila.FECHA_HASTA
    generado = fila.FECHA_GENERACION
    return {
        "id": fila.ID_REPORTE,
        "nombre": nombre_del_reporte(tipo, desde, hasta),
        "fecha": f"{generado.day:02d} {MESES_CORTOS[generado.month - 1]} {generado.year}",
        "formato": FORMATO_PARA_APP[fila.FORMATO],
        "detalle": rango_corto(desde, hasta),
        "periodicidad": "Semanal" if (hasta - desde).days + 1 <= 7 else "Mensual",
        "tipo": TIPO_PARA_APP[tipo],
        "comprometido": float(fila.COMPROMETIDO),
        "cobrado": float(fila.COBRADO),
    }


def buscar_en_catalogo(cursor, tabla: str, columna_id: str, nombre: str, etiqueta: str):
    if nombre.strip().upper() in ("", "TODAS", "TODOS"):
        return None
    cursor.execute(f"SELECT {columna_id} FROM dbo.{tabla} WHERE NOMBRE = ?", nombre.strip())
    fila = cursor.fetchone()
    if fila is None:
        cursor.execute(f"SELECT NOMBRE FROM dbo.{tabla} ORDER BY NOMBRE")
        opciones = ", ".join(["Todas"] + [f.NOMBRE for f in cursor.fetchall()])
        raise LookupError(f"{etiqueta} '{nombre}' no existe. Opciones: {opciones}")
    return fila[0]


def mensaje_de_validacion(detalle: dict) -> str:
    campo = ".".join(str(p) for p in detalle["loc"])
    if detalle["type"] == "missing":
        return f"Falta el campo '{campo}'."
    if detalle["type"].startswith("date"):
        return f"'{campo}' no es una fecha válida; usa el formato AAAA-MM-DD."
    mensaje = detalle["msg"].removeprefix("Value error, ")
    return mensaje[0].upper() + mensaje[1:] + "."


@bp.errorhandler(pyodbc.Error)
def base_no_disponible(_):
    return error("La base de datos no está disponible. Intenta de nuevo.", 503)


@bp.get("")
def listar_reportes():
    cursor = obtener_conexion().cursor()
    cursor.execute(CONSULTA_REPORTES + " ORDER BY h.FECHA_GENERACION DESC")
    return jsonify([fila_a_json(f) for f in cursor.fetchall()])


@bp.get("/<int:id_reporte>")
def obtener_reporte(id_reporte: int):
    cursor = obtener_conexion().cursor()
    cursor.execute(CONSULTA_REPORTES + " WHERE h.ID_REPORTE = ?", id_reporte)
    fila = cursor.fetchone()
    if fila is None:
        return error(f"No existe el reporte {id_reporte}.", 404)
    return jsonify(fila_a_json(fila))


@bp.post("")
def generar_reporte():
    datos = request.get_json(silent=True)
    if datos is None:
        return error("El cuerpo debe ser JSON.", 400)
    try:
        config = ConfiguracionReporte.model_validate(datos)
    except ValidationError as e:
        return error(mensaje_de_validacion(e.errors()[0]), 400)

    conexion = obtener_conexion()
    cursor = conexion.cursor()
    try:
        id_tipo = buscar_en_catalogo(cursor, "CAT_TIPO_REPORTE", "ID_TIPO_REPORTE",
                                     config.tipo, "El tipo de reporte")
        id_formato = buscar_en_catalogo(cursor, "CAT_FORMATO_REPORTE", "ID_FORMATO",
                                        config.formato, "El formato")
        id_linea = buscar_en_catalogo(cursor, "CAT_LINEA_ESTRATEGICA", "ID_LINEA_ESTRATEGICA",
                                      config.lineaEstrategica, "La línea estratégica")
        id_campana = buscar_en_catalogo(cursor, "CAT_CAMPANA_FINANCIERA", "ID_CAMPANA_FINANCIERA",
                                        config.campania, "La campaña")
    except LookupError as e:
        return error(str(e), 400)

    cursor.execute(
        """INSERT INTO dbo.HISTORIAL_REPORTE (ID_TIPO_REPORTE, ID_FORMATO, FECHA_DESDE, FECHA_HASTA)
           OUTPUT INSERTED.ID_REPORTE
           VALUES (?, ?, ?, ?)""",
        id_tipo, id_formato, config.desde, config.hasta)
    id_nuevo = cursor.fetchone()[0]

    if id_linea is not None:
        cursor.execute("INSERT INTO dbo.REPORTE_LINEA_ESTRATEGICA (ID_REPORTE, ID_LINEA_ESTRATEGICA) VALUES (?, ?)",
                       id_nuevo, id_linea)
    if id_campana is not None:
        cursor.execute("INSERT INTO dbo.REPORTE_CAMPANA_FINANCIERA (ID_REPORTE, ID_CAMPANA_FINANCIERA) VALUES (?, ?)",
                       id_nuevo, id_campana)
    conexion.commit()

    cursor.execute(CONSULTA_REPORTES + " WHERE h.ID_REPORTE = ?", id_nuevo)
    return jsonify(fila_a_json(cursor.fetchone())), 201
