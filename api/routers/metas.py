"""Blueprint de metas (avance por asignación).

Dueño: Persona 5 (Metas).

De dónde sale cada número que muestra MetasView.swift:
  - objetivo      dbo.META.MONTO_META. Si el periodo consultado no cubre toda
                  la meta, se prorratea por días para que el porcentaje sea
                  comparable; objetivoTotal siempre trae el monto completo.
  - cobrado       SUM(IMPORTE_COBRADO) de los pagos COBRADO cuya FECHA_PAGO cae
                  dentro del periodo.
  - comprometido  SUM(IMPORTE) de los cobros programados (FECHA_COBRO) del
                  periodo, cobrados o no.
  - donantes      donantes distintos con al menos un pago cobrado en el periodo.
  - mensual       el mismo cobrado agrupado por mes, para la gráfica de barras.

Las llaves del JSON van en camelCase porque son las que espera la app.
"""

import calendar
from datetime import date, timedelta
from decimal import Decimal

import pyodbc
from flask import Blueprint, jsonify, request
from pydantic import ValidationError

from core.db import obtener_conexion
from models.meta import ConsultaMetas

bp = Blueprint("metas", __name__, url_prefix="/metas")

MESES = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio",
         "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]

# Umbrales del semáforo de la pantalla.
VERDE, AMARILLO = 75, 60

# Una fila por meta, ya cruzada con el periodo que se consulta.
CONSULTA_METAS = """
WITH VENTANA AS (
    SELECT CAST(? AS DATE) AS DESDE, CAST(? AS DATE) AS HASTA
)
SELECT
    m.ID_META,
    m.ID_ASIGNACION,
    a.NOMBRE AS ASIGNACION,
    m.MONTO_META,
    m.FECHA_INICIO,
    m.FECHA_FIN,
    r.INICIO,
    r.FIN,
    ISNULL(c.COBRADO, 0)       AS COBRADO,
    ISNULL(c.DONANTES, 0)      AS DONANTES,
    ISNULL(p.COMPROMETIDO, 0)  AS COMPROMETIDO,
    ISNULL(l.LINEA, N'Sin línea registrada') AS LINEA
FROM dbo.META m
JOIN dbo.CAT_ASIGNACION a ON a.ID_ASIGNACION = m.ID_ASIGNACION
CROSS JOIN VENTANA v
-- Traslape entre el periodo de la meta y el periodo consultado.
CROSS APPLY (
    SELECT CASE WHEN m.FECHA_INICIO > v.DESDE THEN m.FECHA_INICIO ELSE v.DESDE END AS INICIO,
           CASE WHEN m.FECHA_FIN    < v.HASTA THEN m.FECHA_FIN    ELSE v.HASTA  END AS FIN
) r
OUTER APPLY (
    SELECT SUM(b.IMPORTE_COBRADO)   AS COBRADO,
           COUNT(DISTINCT d.ID_DONANTE) AS DONANTES
    FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
    JOIN dbo.OPE_DONATIVOS_DONANTE d ON d.ID_DONATIVO = b.ID_DONATIVO
    JOIN dbo.CAT_ESTATUS_PAGO e      ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
    WHERE d.ID_ASIGNACION = m.ID_ASIGNACION
      AND e.NOMBRE = N'COBRADO'
      AND b.FECHA_PAGO BETWEEN r.INICIO AND r.FIN
) c
OUTER APPLY (
    SELECT SUM(b.IMPORTE) AS COMPROMETIDO
    FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
    JOIN dbo.OPE_DONATIVOS_DONANTE d ON d.ID_DONATIVO = b.ID_DONATIVO
    WHERE d.ID_ASIGNACION = m.ID_ASIGNACION
      AND b.FECHA_COBRO BETWEEN r.INICIO AND r.FIN
) p
-- Línea estratégica que más aportó al cobrado de esta asignación.
OUTER APPLY (
    SELECT TOP 1 le.NOMBRE AS LINEA
    FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
    JOIN dbo.OPE_DONATIVOS_DONANTE d      ON d.ID_DONATIVO = b.ID_DONATIVO
    JOIN dbo.CAT_LINEA_ESTRATEGICA le     ON le.ID_LINEA_ESTRATEGICA = d.ID_LINEA_ESTRATEGICA
    JOIN dbo.CAT_ESTATUS_PAGO e           ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
    WHERE d.ID_ASIGNACION = m.ID_ASIGNACION
      AND e.NOMBRE = N'COBRADO'
      AND b.FECHA_PAGO BETWEEN r.INICIO AND r.FIN
    GROUP BY le.NOMBRE
    ORDER BY SUM(b.IMPORTE_COBRADO) DESC
) l
WHERE r.INICIO <= r.FIN
"""

# Cobrado por mes para la gráfica de barras.
CONSULTA_MENSUAL = """
SELECT m.ID_META,
       YEAR(b.FECHA_PAGO)  AS ANIO,
       MONTH(b.FECHA_PAGO) AS MES,
       SUM(b.IMPORTE_COBRADO) AS MONTO
FROM dbo.META m
JOIN dbo.OPE_DONATIVOS_DONANTE d          ON d.ID_ASIGNACION = m.ID_ASIGNACION
JOIN dbo.OPE_BITACORA_PAGOS_DONATIVOS b   ON b.ID_DONATIVO = d.ID_DONATIVO
JOIN dbo.CAT_ESTATUS_PAGO e               ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
WHERE e.NOMBRE = N'COBRADO'
  AND b.FECHA_PAGO BETWEEN ? AND ?
  AND b.FECHA_PAGO BETWEEN m.FECHA_INICIO AND m.FECHA_FIN
GROUP BY m.ID_META, YEAR(b.FECHA_PAGO), MONTH(b.FECHA_PAGO)
"""


# ---------------------------------------------------------------- utilidades

def error(mensaje: str, codigo: int):
    return jsonify({"error": mensaje}), codigo


def ventana_del_periodo(periodo: str, hoy: date) -> tuple[date, date]:
    """Convierte el Picker de la app (Día, Semana, Mes, ...) en un rango."""
    if periodo == "dia":
        return hoy, hoy
    if periodo == "semana":
        lunes = hoy - timedelta(days=hoy.weekday())
        return lunes, lunes + timedelta(days=6)
    if periodo == "mes":
        ultimo = calendar.monthrange(hoy.year, hoy.month)[1]
        return date(hoy.year, hoy.month, 1), date(hoy.year, hoy.month, ultimo)
    if periodo == "trimestre":
        primer_mes = 3 * ((hoy.month - 1) // 3) + 1
        ultimo_mes = primer_mes + 2
        ultimo = calendar.monthrange(hoy.year, ultimo_mes)[1]
        return date(hoy.year, primer_mes, 1), date(hoy.year, ultimo_mes, ultimo)
    return date(hoy.year, 1, 1), date(hoy.year, 12, 31)


def dias(desde: date, hasta: date) -> int:
    return (hasta - desde).days + 1


def semaforo(porcentaje: int) -> str:
    if porcentaje >= VERDE:
        return "verde"
    if porcentaje >= AMARILLO:
        return "amarillo"
    return "rojo"


def meses_del_rango(desde: date, hasta: date) -> list[tuple[int, int]]:
    """[(2026, 7), (2026, 8), (2026, 9)] para que la gráfica no salte meses."""
    meses, anio, mes = [], desde.year, desde.month
    while (anio, mes) <= (hasta.year, hasta.month):
        meses.append((anio, mes))
        anio, mes = (anio + 1, 1) if mes == 12 else (anio, mes + 1)
    return meses


def numero(valor) -> float:
    """Flask serializa Decimal como texto y Swift espera un número."""
    return float(valor if valor is not None else 0)


def objetivo_prorrateado(fila) -> Decimal:
    """MONTO_META ajustado a la parte de la meta que cae en el periodo."""
    dias_meta = dias(fila.FECHA_INICIO, fila.FECHA_FIN)
    dias_traslape = dias(fila.INICIO, fila.FIN)
    if dias_traslape >= dias_meta:
        return fila.MONTO_META
    return fila.MONTO_META * Decimal(dias_traslape) / Decimal(dias_meta)


def fila_a_json(fila, mensual: list[dict]) -> dict:
    objetivo = objetivo_prorrateado(fila)
    cobrado = fila.COBRADO or Decimal(0)
    porcentaje = int((cobrado / objetivo * 100).to_integral_value()) if objetivo else 0
    return {
        "id": fila.ID_META,
        "nombre": fila.ASIGNACION.title(),
        "lineaEstrategica": fila.LINEA.title(),
        "desde": fila.INICIO.isoformat(),
        "hasta": fila.FIN.isoformat(),
        "objetivo": round(numero(objetivo), 2),
        "objetivoTotal": numero(fila.MONTO_META),
        "comprometido": numero(fila.COMPROMETIDO),
        "cobrado": numero(cobrado),
        # Nunca negativo: una meta rebasada muestra 0 faltante, no un hueco en la dona.
        "faltante": round(max(numero(objetivo) - numero(cobrado), 0.0), 2),
        "porcentaje": porcentaje,
        "semaforo": semaforo(porcentaje),
        "donantes": fila.DONANTES,
        "mensual": mensual,
    }


def leer_parametros():
    """Valida ?periodo=, ?desde= y ?hasta= y devuelve el rango a consultar."""
    consulta = ConsultaMetas.model_validate(request.args.to_dict())
    if consulta.desde and consulta.hasta:
        return consulta.desde, consulta.hasta
    return ventana_del_periodo(consulta.periodo, date.today())


def avances_mensuales(cursor, desde: date, hasta: date) -> dict[int, list[dict]]:
    """Cobrado por mes de cada meta, con los meses vacíos en cero."""
    cursor.execute(CONSULTA_MENSUAL, desde, hasta)
    montos = {(f.ID_META, f.ANIO, f.MES): f.MONTO for f in cursor.fetchall()}

    resultado: dict[int, list[dict]] = {}
    for id_meta in {clave[0] for clave in montos}:
        resultado[id_meta] = [
            {
                "anio": anio,
                "mes": mes,
                "nombre": MESES[mes - 1],
                "monto": numero(montos.get((id_meta, anio, mes), 0)),
            }
            for anio, mes in meses_del_rango(desde, hasta)
        ]
    return resultado


@bp.errorhandler(pyodbc.Error)
def base_no_disponible(_):
    return error("La base de datos no está disponible. Intenta de nuevo.", 503)


# ---------------------------------------------------------------- endpoints

@bp.get("")
def listar_metas():
    """Metas del periodo con su avance. GET /metas?periodo=trimestre"""
    try:
        desde, hasta = leer_parametros()
    except ValidationError as e:
        return error(e.errors()[0]["msg"].removeprefix("Value error, "), 400)

    cursor = obtener_conexion().cursor()
    cursor.execute(CONSULTA_METAS + " ORDER BY a.NOMBRE", desde, hasta)
    filas = cursor.fetchall()
    mensuales = avances_mensuales(cursor, desde, hasta)

    return jsonify({
        "desde": desde.isoformat(),
        "hasta": hasta.isoformat(),
        "metas": [fila_a_json(f, mensuales.get(f.ID_META, [])) for f in filas],
    })


@bp.get("/<int:id_meta>")
def obtener_meta(id_meta: int):
    """Una meta con su avance mensual. GET /metas/1?periodo=trimestre"""
    try:
        desde, hasta = leer_parametros()
    except ValidationError as e:
        return error(e.errors()[0]["msg"].removeprefix("Value error, "), 400)

    cursor = obtener_conexion().cursor()
    cursor.execute(CONSULTA_METAS + " AND m.ID_META = ?", desde, hasta, id_meta)
    fila = cursor.fetchone()
    if fila is None:
        return error(f"No existe la meta {id_meta} en el periodo consultado.", 404)

    mensuales = avances_mensuales(cursor, desde, hasta)
    return jsonify(fila_a_json(fila, mensuales.get(id_meta, [])))
