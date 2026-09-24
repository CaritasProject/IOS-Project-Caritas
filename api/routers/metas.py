import calendar
from datetime import date, timedelta
from decimal import Decimal

import pyodbc
from flask import Blueprint, jsonify, request
from pydantic import ValidationError

from core.auth import requiere_sesion
from core.db import obtener_conexion
from models.meta import ConsultaMetas

bp = Blueprint("metas", __name__, url_prefix="/metas")

MESES = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio",
         "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]

PORCENTAJE_VERDE = 75
PORCENTAJE_AMARILLO = 60

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
    traslape.INICIO,
    traslape.FIN,
    ISNULL(cobrado.COBRADO, 0)            AS COBRADO,
    ISNULL(cobrado.DONANTES, 0)           AS DONANTES,
    ISNULL(programado.COMPROMETIDO, 0)    AS COMPROMETIDO,
    ISNULL(linea_principal.LINEA, N'Sin línea registrada') AS LINEA
FROM dbo.META m
JOIN dbo.CAT_ASIGNACION a ON a.ID_ASIGNACION = m.ID_ASIGNACION
CROSS JOIN VENTANA v
CROSS APPLY (
    SELECT CASE WHEN m.FECHA_INICIO > v.DESDE THEN m.FECHA_INICIO ELSE v.DESDE END AS INICIO,
           CASE WHEN m.FECHA_FIN    < v.HASTA THEN m.FECHA_FIN    ELSE v.HASTA  END AS FIN
) traslape
OUTER APPLY (
    SELECT SUM(b.IMPORTE_COBRADO)       AS COBRADO,
           COUNT(DISTINCT d.ID_DONANTE) AS DONANTES
    FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
    JOIN dbo.OPE_DONATIVOS_DONANTE d ON d.ID_DONATIVO = b.ID_DONATIVO
    JOIN dbo.CAT_ESTATUS_PAGO e      ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
    WHERE d.ID_ASIGNACION = m.ID_ASIGNACION
      AND e.NOMBRE = N'COBRADO'
      AND b.FECHA_PAGO BETWEEN traslape.INICIO AND traslape.FIN
) cobrado
OUTER APPLY (
    SELECT SUM(b.IMPORTE) AS COMPROMETIDO
    FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
    JOIN dbo.OPE_DONATIVOS_DONANTE d ON d.ID_DONATIVO = b.ID_DONATIVO
    WHERE d.ID_ASIGNACION = m.ID_ASIGNACION
      AND b.FECHA_COBRO BETWEEN traslape.INICIO AND traslape.FIN
) programado
OUTER APPLY (
    SELECT TOP 1 le.NOMBRE AS LINEA
    FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
    JOIN dbo.OPE_DONATIVOS_DONANTE d      ON d.ID_DONATIVO = b.ID_DONATIVO
    JOIN dbo.CAT_LINEA_ESTRATEGICA le     ON le.ID_LINEA_ESTRATEGICA = d.ID_LINEA_ESTRATEGICA
    JOIN dbo.CAT_ESTATUS_PAGO e           ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
    WHERE d.ID_ASIGNACION = m.ID_ASIGNACION
      AND e.NOMBRE = N'COBRADO'
      AND b.FECHA_PAGO BETWEEN traslape.INICIO AND traslape.FIN
    GROUP BY le.NOMBRE
    ORDER BY SUM(b.IMPORTE_COBRADO) DESC
) linea_principal
WHERE traslape.INICIO <= traslape.FIN
"""

CONSULTA_COBRADO_POR_MES = """
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


def error(mensaje: str, codigo: int):
    return jsonify({"error": mensaje}), codigo


def error_de_validacion(excepcion: ValidationError):
    mensaje = excepcion.errors()[0]["msg"].removeprefix("Value error, ")
    return error(mensaje, 400)


def ultimo_dia_del_mes(anio: int, mes: int) -> date:
    return date(anio, mes, calendar.monthrange(anio, mes)[1])


def ventana_del_periodo(periodo: str, hoy: date) -> tuple[date, date]:
    if periodo == "dia":
        return hoy, hoy
    if periodo == "semana":
        lunes = hoy - timedelta(days=hoy.weekday())
        return lunes, lunes + timedelta(days=6)
    if periodo == "mes":
        return date(hoy.year, hoy.month, 1), ultimo_dia_del_mes(hoy.year, hoy.month)
    if periodo == "trimestre":
        primer_mes = 3 * ((hoy.month - 1) // 3) + 1
        return date(hoy.year, primer_mes, 1), ultimo_dia_del_mes(hoy.year, primer_mes + 2)
    return date(hoy.year, 1, 1), date(hoy.year, 12, 31)


def dias_entre(desde: date, hasta: date) -> int:
    return (hasta - desde).days + 1


def semaforo(porcentaje: int) -> str:
    if porcentaje >= PORCENTAJE_VERDE:
        return "verde"
    if porcentaje >= PORCENTAJE_AMARILLO:
        return "amarillo"
    return "rojo"


def meses_del_rango(desde: date, hasta: date) -> list[tuple[int, int]]:
    meses = []
    anio, mes = desde.year, desde.month
    while (anio, mes) <= (hasta.year, hasta.month):
        meses.append((anio, mes))
        if mes == 12:
            anio, mes = anio + 1, 1
        else:
            mes += 1
    return meses


def numero(valor) -> float:
    return float(valor if valor is not None else 0)


def objetivo_prorrateado(fila) -> Decimal:
    dias_de_la_meta = dias_entre(fila.FECHA_INICIO, fila.FECHA_FIN)
    dias_en_el_periodo = dias_entre(fila.INICIO, fila.FIN)
    if dias_en_el_periodo >= dias_de_la_meta:
        return fila.MONTO_META
    return fila.MONTO_META * Decimal(dias_en_el_periodo) / Decimal(dias_de_la_meta)


def porcentaje_de_avance(cobrado: Decimal, objetivo: Decimal) -> int:
    if not objetivo:
        return 0
    return int((cobrado / objetivo * 100).to_integral_value())


def fila_a_json(fila, mensual: list[dict]) -> dict:
    objetivo = objetivo_prorrateado(fila)
    cobrado = fila.COBRADO or Decimal(0)
    porcentaje = porcentaje_de_avance(cobrado, objetivo)
    faltante = max(numero(objetivo) - numero(cobrado), 0.0)
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
        "faltante": round(faltante, 2),
        "porcentaje": porcentaje,
        "semaforo": semaforo(porcentaje),
        "donantes": fila.DONANTES,
        "mensual": mensual,
    }


def rango_de_la_consulta() -> tuple[date, date]:
    consulta = ConsultaMetas.model_validate(request.args.to_dict())
    if consulta.desde and consulta.hasta:
        return consulta.desde, consulta.hasta
    return ventana_del_periodo(consulta.periodo, date.today())


def cobrado_por_mes(cursor, desde: date, hasta: date) -> dict[int, list[dict]]:
    cursor.execute(CONSULTA_COBRADO_POR_MES, desde, hasta)
    montos = {(fila.ID_META, fila.ANIO, fila.MES): fila.MONTO for fila in cursor.fetchall()}
    metas_con_cobros = {id_meta for id_meta, _, _ in montos}

    resultado = {}
    for id_meta in metas_con_cobros:
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


def metas_del_periodo(desde: date, hasta: date):
    cursor = obtener_conexion().cursor()
    cursor.execute(CONSULTA_METAS + " ORDER BY a.NOMBRE", desde, hasta)
    filas = cursor.fetchall()
    mensuales = cobrado_por_mes(cursor, desde, hasta)

    return jsonify({
        "desde": desde.isoformat(),
        "hasta": hasta.isoformat(),
        "metas": [fila_a_json(fila, mensuales.get(fila.ID_META, [])) for fila in filas],
    })


@bp.errorhandler(pyodbc.Error)
def base_no_disponible(_):
    return error("La base de datos no está disponible. Intenta de nuevo.", 503)


@bp.get("")
@requiere_sesion
def listar_metas():
    try:
        desde, hasta = rango_de_la_consulta()
    except ValidationError as excepcion:
        return error_de_validacion(excepcion)
    return metas_del_periodo(desde, hasta)


@bp.get("/periodo/<periodo>")
@requiere_sesion
def listar_metas_por_periodo(periodo: str):
    try:
        consulta = ConsultaMetas.model_validate({"periodo": periodo})
    except ValidationError as excepcion:
        return error_de_validacion(excepcion)
    desde, hasta = ventana_del_periodo(consulta.periodo, date.today())
    return metas_del_periodo(desde, hasta)


@bp.get("/<int:id_meta>")
@requiere_sesion
def obtener_meta(id_meta: int):
    try:
        desde, hasta = rango_de_la_consulta()
    except ValidationError as excepcion:
        return error_de_validacion(excepcion)

    cursor = obtener_conexion().cursor()
    cursor.execute(CONSULTA_METAS + " AND m.ID_META = ?", desde, hasta, id_meta)
    fila = cursor.fetchone()
    if fila is None:
        return error(f"No existe la meta {id_meta} en el periodo consultado.", 404)

    mensuales = cobrado_por_mes(cursor, desde, hasta)
    return jsonify(fila_a_json(fila, mensuales.get(id_meta, [])))
