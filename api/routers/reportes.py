import calendar
import csv
import io
from datetime import date, datetime

import pyodbc
from flask import Blueprint, Response, jsonify, request
from pydantic import ValidationError

from core.archivos import archivo_excel, archivo_pdf, titulo_columna, valor_legible
from core.db import obtener_conexion
from models.reporte import ConfiguracionReporte
from routers.metas import CONSULTA_METAS, objetivo_prorrateado

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

FILTRO_ALCANCE = """
      AND (NOT EXISTS (SELECT 1 FROM dbo.REPORTE_LINEA_ESTRATEGICA al WHERE al.ID_REPORTE = h.ID_REPORTE)
           OR d.ID_LINEA_ESTRATEGICA IN (SELECT al.ID_LINEA_ESTRATEGICA FROM dbo.REPORTE_LINEA_ESTRATEGICA al
                                         WHERE al.ID_REPORTE = h.ID_REPORTE))
      AND (NOT EXISTS (SELECT 1 FROM dbo.REPORTE_CAMPANA_FINANCIERA ac WHERE ac.ID_REPORTE = h.ID_REPORTE)
           OR d.ID_CAMPANA_FINANCIERA IN (SELECT ac.ID_CAMPANA_FINANCIERA FROM dbo.REPORTE_CAMPANA_FINANCIERA ac
                                          WHERE ac.ID_REPORTE = h.ID_REPORTE))
"""

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
    WHERE b.FECHA_COBRO BETWEEN h.FECHA_DESDE AND h.FECHA_HASTA""" + FILTRO_ALCANCE + """) m
"""

CONSULTA_COBROS = """
SELECT b.ID_BITACORA, b.FECHA_COBRO, b.FECHA_VENCIMIENTO, b.FECHA_PAGO,
       COALESCE(o.RAZON_SOCIAL, CONCAT_WS(N' ', o.NOMBRE, o.A_PATERNO, o.A_MATERNO)) AS DONANTE,
       le.NOMBRE AS LINEA, a.NOMBRE AS ASIGNACION, c.NOMBRE AS CAMPANA, fp.NOMBRE AS FORMA_PAGO,
       b.IMPORTE, b.IMPORTE_COBRADO, ep.NOMBRE AS ESTATUS
FROM dbo.HISTORIAL_REPORTE h
JOIN dbo.OPE_BITACORA_PAGOS_DONATIVOS b ON b.FECHA_COBRO BETWEEN h.FECHA_DESDE AND h.FECHA_HASTA
JOIN dbo.OPE_DONATIVOS_DONANTE d        ON d.ID_DONATIVO = b.ID_DONATIVO
JOIN dbo.OPE_DONANTES o                 ON o.ID_DONANTE = d.ID_DONANTE
JOIN dbo.CAT_LINEA_ESTRATEGICA le       ON le.ID_LINEA_ESTRATEGICA = d.ID_LINEA_ESTRATEGICA
JOIN dbo.CAT_ASIGNACION a               ON a.ID_ASIGNACION = d.ID_ASIGNACION
LEFT JOIN dbo.CAT_CAMPANA_FINANCIERA c  ON c.ID_CAMPANA_FINANCIERA = d.ID_CAMPANA_FINANCIERA
JOIN dbo.CAT_FORMA_PAGO fp              ON fp.ID_FORMA_PAGO = d.ID_FORMA_PAGO
JOIN dbo.CAT_ESTATUS_PAGO ep            ON ep.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
WHERE h.ID_REPORTE = ?""" + FILTRO_ALCANCE + """
ORDER BY b.FECHA_COBRO, b.ID_BITACORA
"""

CONSULTA_LLAMADAS = """
SELECT r.ID_LLAMADA, r.FECHA_LLAMADA,
       COALESCE(o.RAZON_SOCIAL, CONCAT_WS(N' ', o.NOMBRE, o.A_PATERNO, o.A_MATERNO)) AS DONANTE,
       u.NOMBRE AS TELEFONISTA, r.RESULTADO, r.COMENTARIOS
FROM dbo.HISTORIAL_REPORTE h
JOIN dbo.REGISTRO_LLAMADA r ON CAST(r.FECHA_LLAMADA AS DATE) BETWEEN h.FECHA_DESDE AND h.FECHA_HASTA
JOIN dbo.OPE_DONANTES o     ON o.ID_DONANTE = r.ID_DONANTE
JOIN dbo.USUARIO u          ON u.ID_USUARIO = r.ID_USUARIO
WHERE h.ID_REPORTE = ?
ORDER BY r.FECHA_LLAMADA, r.ID_LLAMADA
"""

COLUMNAS_COBROS = ["id_cobro", "fecha_cobro", "fecha_vencimiento", "fecha_pago", "donante",
                   "linea_estrategica", "asignacion", "campana", "forma_pago",
                   "importe_comprometido", "importe_cobrado", "estatus"]
COLUMNAS_LLAMADAS = ["id_llamada", "fecha_llamada", "donante", "telefonista", "resultado", "comentarios"]
COLUMNAS_METAS = ["id_meta", "asignacion", "desde", "hasta", "objetivo_total", "objetivo_periodo",
                  "comprometido", "cobrado", "faltante", "porcentaje_avance"]


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


def texto_fecha(valor) -> str:
    return valor.isoformat() if valor else ""


def texto_monto(valor) -> str:
    return f"{valor or 0:.2f}"


def filas_de_cobros(cursor, id_reporte: int, es_cobranza: bool):
    cursor.execute(CONSULTA_COBROS, id_reporte)
    hoy = date.today()
    filas = []
    for c in cursor.fetchall():
        fila = [c.ID_BITACORA, texto_fecha(c.FECHA_COBRO), texto_fecha(c.FECHA_VENCIMIENTO),
                texto_fecha(c.FECHA_PAGO), c.DONANTE, c.LINEA, c.ASIGNACION, c.CAMPANA or "",
                c.FORMA_PAGO, texto_monto(c.IMPORTE), texto_monto(c.IMPORTE_COBRADO), c.ESTATUS]
        if es_cobranza:
            vencido = c.ESTATUS == "RECHAZADO" or (c.ESTATUS == "PENDIENTE" and c.FECHA_VENCIMIENTO < hoy)
            dias_atraso = max((hoy - c.FECHA_VENCIMIENTO).days, 0) if vencido else 0
            fila += ["SÍ" if vencido else "NO", dias_atraso]
        filas.append(fila)
    if es_cobranza:
        filas.sort(key=lambda f: -f[-1])
        return COLUMNAS_COBROS + ["vencido", "dias_atraso"], filas
    return COLUMNAS_COBROS, filas


def filas_de_llamadas(cursor, id_reporte: int):
    cursor.execute(CONSULTA_LLAMADAS, id_reporte)
    filas = [[l.ID_LLAMADA, l.FECHA_LLAMADA.strftime("%Y-%m-%d %H:%M"), l.DONANTE,
              l.TELEFONISTA, l.RESULTADO, l.COMENTARIOS or ""] for l in cursor.fetchall()]
    return COLUMNAS_LLAMADAS, filas


def filas_de_metas(cursor, desde: date, hasta: date):
    cursor.execute(CONSULTA_METAS + " ORDER BY a.NOMBRE", desde, hasta)
    filas = []
    for m in cursor.fetchall():
        objetivo = objetivo_prorrateado(m)
        cobrado = m.COBRADO or 0
        porcentaje = int((cobrado / objetivo * 100).to_integral_value()) if objetivo else 0
        filas.append([m.ID_META, m.ASIGNACION, texto_fecha(m.INICIO), texto_fecha(m.FIN),
                      texto_monto(m.MONTO_META), texto_monto(objetivo), texto_monto(m.COMPROMETIDO),
                      texto_monto(cobrado), texto_monto(max(objetivo - cobrado, 0)), porcentaje])
    return COLUMNAS_METAS, filas


def respuesta_csv(nombre_archivo: str, columnas: list, filas: list) -> Response:
    salida = io.StringIO()
    escritor = csv.writer(salida)
    escritor.writerow(columnas)
    escritor.writerows(filas)
    return Response("\ufeff" + salida.getvalue(), mimetype="text/csv",
                    headers={"Content-Disposition": f'attachment; filename="{nombre_archivo}"'})


EXTENSIONES = {"PDF": "pdf", "EXCEL": "xlsx", "CSV": "csv"}
TIPOS_MIME = {"pdf": "application/pdf",
              "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"}


def alcance(cursor, id_reporte: int, tabla: str, catalogo: str, columna_id: str) -> str:
    cursor.execute(f"""SELECT c.NOMBRE FROM dbo.{tabla} a
                       JOIN dbo.{catalogo} c ON c.{columna_id} = a.{columna_id}
                       WHERE a.ID_REPORTE = ? ORDER BY c.NOMBRE""", id_reporte)
    nombres = [f.NOMBRE for f in cursor.fetchall()]
    return ", ".join(nombres) if nombres else "Todas"


def contenido_del_reporte(cursor, id_reporte: int):
    cursor.execute(CONSULTA_REPORTES + " WHERE h.ID_REPORTE = ?", id_reporte)
    reporte = cursor.fetchone()
    if reporte is None:
        return None

    tipo, desde, hasta = reporte.TIPO_REPORTE, reporte.FECHA_DESDE, reporte.FECHA_HASTA
    if tipo == "TELEMARKETING":
        columnas, filas = filas_de_llamadas(cursor, id_reporte)
    elif tipo == "METAS":
        columnas, filas = filas_de_metas(cursor, desde, hasta)
    else:
        columnas, filas = filas_de_cobros(cursor, id_reporte, tipo == "COBRANZA")
    return reporte, columnas, filas


def detalles_del_reporte(cursor, reporte) -> list:
    return [
        ("Tipo", TIPO_PARA_APP[reporte.TIPO_REPORTE]),
        ("Periodo", f"{reporte.FECHA_DESDE.isoformat()} a {reporte.FECHA_HASTA.isoformat()}"),
        ("Línea estratégica", alcance(cursor, reporte.ID_REPORTE, "REPORTE_LINEA_ESTRATEGICA",
                                      "CAT_LINEA_ESTRATEGICA", "ID_LINEA_ESTRATEGICA")),
        ("Campaña", alcance(cursor, reporte.ID_REPORTE, "REPORTE_CAMPANA_FINANCIERA",
                            "CAT_CAMPANA_FINANCIERA", "ID_CAMPANA_FINANCIERA")),
        ("Comprometido", f"${reporte.COMPROMETIDO:,.2f}"),
        ("Cobrado", f"${reporte.COBRADO:,.2f}"),
        ("Datos al", datetime.now().strftime("%Y-%m-%d %H:%M")),
    ]


def nombre_de_archivo(reporte, extension: str) -> str:
    return (f"reporte-{reporte.ID_REPORTE}_{reporte.TIPO_REPORTE.lower()}_"
            f"{reporte.FECHA_DESDE.isoformat()}_{reporte.FECHA_HASTA.isoformat()}.{extension}")


@bp.get("/<int:id_reporte>/csv")
def descargar_csv(id_reporte: int):
    cursor = obtener_conexion().cursor()
    contenido = contenido_del_reporte(cursor, id_reporte)
    if contenido is None:
        return error(f"No existe el reporte {id_reporte}.", 404)

    reporte, columnas, filas = contenido
    return respuesta_csv(nombre_de_archivo(reporte, "csv"), columnas, filas)


@bp.get("/<int:id_reporte>/archivo")
def descargar_archivo(id_reporte: int):
    cursor = obtener_conexion().cursor()
    contenido = contenido_del_reporte(cursor, id_reporte)
    if contenido is None:
        return error(f"No existe el reporte {id_reporte}.", 404)

    reporte, columnas, filas = contenido
    formato = request.args.get("formato", reporte.FORMATO).strip().upper()
    if formato not in EXTENSIONES:
        return error("El formato debe ser PDF, Excel o CSV.", 400)

    extension = EXTENSIONES[formato]
    nombre = nombre_de_archivo(reporte, extension)
    if extension == "csv":
        return respuesta_csv(nombre, columnas, filas)

    titulo = nombre_del_reporte(reporte.TIPO_REPORTE, reporte.FECHA_DESDE, reporte.FECHA_HASTA)
    detalles = detalles_del_reporte(cursor, reporte)
    if extension == "pdf":
        datos = archivo_pdf(titulo, detalles, columnas, filas)
    else:
        datos = archivo_excel(titulo, detalles, columnas, filas)
    return Response(datos, mimetype=TIPOS_MIME[extension],
                    headers={"Content-Disposition": f'attachment; filename="{nombre}"'})


@bp.get("/<int:id_reporte>/datos")
def datos_para_vista_previa(id_reporte: int):
    cursor = obtener_conexion().cursor()
    contenido = contenido_del_reporte(cursor, id_reporte)
    if contenido is None:
        return error(f"No existe el reporte {id_reporte}.", 404)

    _, columnas, filas = contenido
    return jsonify({
        "columnas": [{"id": i, "nombre": titulo_columna(c)} for i, c in enumerate(columnas)],
        "filas": [{"id": i,
                   "celdas": [{"id": j, "valor": valor_legible(c, v)}
                              for j, (c, v) in enumerate(zip(columnas, fila))]}
                  for i, fila in enumerate(filas)],
        "datosAl": datetime.now().strftime("%d/%m/%Y %H:%M"),
    })
