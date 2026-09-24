from datetime import date, timedelta

from flask import Blueprint, jsonify

from core.auth import requiere_sesion
from core.db import obtener_conexion

bp = Blueprint("resumen", __name__, url_prefix="/resumen")

PERIODOS = ["dia", "semana", "mes", "trimestre", "ano"]

MESES = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
         "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]

MESES_CORTOS = ["Ene", "Feb", "Mar", "Abr", "May", "Jun",
                "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]

DIAS_CORTOS = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]


def rango_del_periodo(periodo, hoy):
    if periodo == "dia":
        etiqueta = f"{hoy.day} de {MESES[hoy.month - 1]} {hoy.year}"
        return hoy, hoy, etiqueta

    if periodo == "semana":
        desde = hoy - timedelta(days=hoy.weekday())
        hasta = desde + timedelta(days=6)
        etiqueta = f"Semana del {desde.day} de {MESES[desde.month - 1]}"
        return desde, hasta, etiqueta

    if periodo == "trimestre":
        numero_trimestre = (hoy.month - 1) // 3
        mes_inicio = numero_trimestre * 3 + 1
        desde = date(hoy.year, mes_inicio, 1)
        if mes_inicio + 3 > 12:
            hasta = date(hoy.year, 12, 31)
        else:
            hasta = date(hoy.year, mes_inicio + 3, 1) - timedelta(days=1)
        etiqueta = f"Trimestre {numero_trimestre + 1} de {hoy.year}"
        return desde, hasta, etiqueta

    if periodo == "ano":
        desde = date(hoy.year, 1, 1)
        hasta = date(hoy.year, 12, 31)
        return desde, hasta, f"{hoy.year}"

    desde = date(hoy.year, hoy.month, 1)
    if hoy.month == 12:
        hasta = date(hoy.year, 12, 31)
    else:
        hasta = date(hoy.year, hoy.month + 1, 1) - timedelta(days=1)
    etiqueta = f"{MESES[hoy.month - 1]} {hoy.year}"
    return desde, hasta, etiqueta


def numero(valor):
    if valor is None:
        return 0.0
    return float(valor)


def porcentaje(parte, total):
    if not total:
        return 0.0
    return round(float(parte) / float(total) * 100, 1)


def consultar_ingresos(cursor, desde, hasta):
    cursor.execute(
        """
        SELECT
            ISNULL(SUM(b.IMPORTE), 0)                                                  AS COMPROMETIDO,
            COUNT(*)                                                                   AS COMPROMISOS,
            ISNULL(SUM(CASE WHEN ep.NOMBRE = N'COBRADO' THEN b.IMPORTE_COBRADO END), 0) AS COBRADO,
            SUM(CASE WHEN ep.NOMBRE = N'COBRADO' THEN 1 ELSE 0 END)                    AS COBROS_APLICADOS
        FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
        JOIN dbo.CAT_ESTATUS_PAGO ep ON ep.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
        WHERE b.FECHA_COBRO BETWEEN ? AND ?
        """,
        desde, hasta,
    )
    fila = cursor.fetchone()
    comprometido = numero(fila.COMPROMETIDO)
    cobrado = numero(fila.COBRADO)

    ingresos = {}
    ingresos["comprometido"] = comprometido
    ingresos["compromisos"] = fila.COMPROMISOS or 0
    ingresos["cobrado"] = cobrado
    ingresos["cobrosAplicados"] = fila.COBROS_APLICADOS or 0
    ingresos["porcentajeCobranza"] = porcentaje(cobrado, comprometido)
    return ingresos


def consultar_meta(cursor, desde, hasta, cobrado):
    cursor.execute(
        """
        SELECT ISNULL(SUM(m.MONTO_META), 0) AS MONTO_META
        FROM dbo.META m
        WHERE m.FECHA_INICIO <= ? AND m.FECHA_FIN >= ?
        """,
        hasta, desde,
    )
    fila = cursor.fetchone()
    monto_meta = numero(fila.MONTO_META)

    meta = {}
    meta["montoMeta"] = monto_meta
    meta["cobrado"] = cobrado
    meta["porcentaje"] = porcentaje(cobrado, monto_meta)
    return meta


def consultar_riesgo(cursor):
    cursor.execute(
        """
        SELECT
            COUNT(*)                                                                AS TOTAL,
            SUM(CASE WHEN v.NIVEL_RIESGO = N'ROJO' THEN 1 ELSE 0 END)                AS CRITICOS,
            SUM(CASE WHEN v.NIVEL_RIESGO IN (N'NARANJA', N'AMARILLO') THEN 1 ELSE 0 END) AS MODERADOS
        FROM dbo.VW_DONANTE_INDICADORES v
        WHERE v.EN_RIESGO = 1
        """
    )
    fila = cursor.fetchone()

    riesgo = {}
    riesgo["total"] = fila.TOTAL or 0
    riesgo["criticos"] = fila.CRITICOS or 0
    riesgo["moderados"] = fila.MODERADOS or 0
    return riesgo


def consultar_top_diez(cursor):
    cursor.execute(
        """
        SELECT
            SUM(CASE WHEN v.ALTO_VALOR = 1 THEN 1 ELSE 0 END)                             AS TOTAL,
            SUM(CASE WHEN v.ALTO_VALOR = 1 AND v.EN_RIESGO = 0 THEN 1 ELSE 0 END)         AS AL_CORRIENTE,
            ISNULL(SUM(CASE WHEN v.ALTO_VALOR = 1 THEN v.ACUMULADO_12_MESES END), 0)      AS APORTADO,
            ISNULL(SUM(v.ACUMULADO_12_MESES), 0)                                          AS TOTAL_12_MESES
        FROM dbo.VW_DONANTE_INDICADORES v
        """
    )
    fila = cursor.fetchone()

    top = {}
    top["total"] = fila.TOTAL or 0
    top["alCorriente"] = fila.AL_CORRIENTE or 0
    top["porcentajeDeLoCobrado"] = porcentaje(fila.APORTADO, fila.TOTAL_12_MESES)
    return top


def consultar_telemarketing(cursor, desde, hasta):
    cursor.execute(
        """
        SELECT COUNT(*) AS LLAMADAS
        FROM dbo.REGISTRO_LLAMADA l
        WHERE CAST(l.FECHA_LLAMADA AS DATE) BETWEEN ? AND ?
        """,
        desde, hasta,
    )
    fila = cursor.fetchone()
    llamadas = fila.LLAMADAS or 0

    cursor.execute(
        """
        SELECT COUNT(*) AS COMPROMISOS
        FROM dbo.OPE_DONATIVOS_DONANTE dv
        WHERE dv.FECHA_ALTA BETWEEN ? AND ?
        """,
        desde, hasta,
    )
    fila = cursor.fetchone()
    compromisos = fila.COMPROMISOS or 0

    telemarketing = {}
    telemarketing["llamadas"] = llamadas
    telemarketing["compromisosGenerados"] = compromisos
    telemarketing["tasaConversion"] = porcentaje(compromisos, llamadas)
    return telemarketing


def tramo_de_fecha(periodo, fecha):
    """Devuelve (clave, etiqueta) de la barra de la gráfica donde cae la fecha.

    FECHA_COBRO es DATE, sin hora, así que el día no se puede partir en horas:
    el periodo "dia" es una sola barra.
    """
    if periodo == "dia":
        return fecha, f"{fecha.day} {MESES_CORTOS[fecha.month - 1]}"

    if periodo == "semana":
        return fecha, f"{DIAS_CORTOS[fecha.weekday()]} {fecha.day}"

    if periodo == "ano":
        return fecha.month, MESES_CORTOS[fecha.month - 1]

    # Mes y trimestre van por semana. La clave es el lunes de esa semana y no el
    # número ISO, porque del 29 al 31 de diciembre pueden ser la "Sem 1" del año siguiente.
    lunes = fecha - timedelta(days=fecha.weekday())
    return lunes, f"Sem {fecha.isocalendar()[1]}"


def armar_tramos(periodo, desde, hasta, filas):
    """Una barra por tramo del periodo, en orden, incluidas las que no tuvieron cobros."""
    tramos = {}
    fecha = desde
    while fecha <= hasta:
        clave, etiqueta = tramo_de_fecha(periodo, fecha)
        if clave not in tramos:
            tramo = {}
            tramo["orden"] = len(tramos) + 1
            tramo["etiqueta"] = etiqueta
            tramo["comprometido"] = 0.0
            tramo["cobrado"] = 0.0
            tramos[clave] = tramo
        fecha = fecha + timedelta(days=1)

    for fila in filas:
        clave, etiqueta = tramo_de_fecha(periodo, fila.FECHA)
        tramos[clave]["comprometido"] += numero(fila.COMPROMETIDO)
        tramos[clave]["cobrado"] += numero(fila.COBRADO)

    return list(tramos.values())


def consultar_ingresos_por_tramo(cursor, periodo, desde, hasta):
    cursor.execute(
        """
        SELECT
            b.FECHA_COBRO                                                              AS FECHA,
            ISNULL(SUM(b.IMPORTE), 0)                                                  AS COMPROMETIDO,
            ISNULL(SUM(CASE WHEN ep.NOMBRE = N'COBRADO' THEN b.IMPORTE_COBRADO END), 0) AS COBRADO
        FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
        JOIN dbo.CAT_ESTATUS_PAGO ep ON ep.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
        WHERE b.FECHA_COBRO BETWEEN ? AND ?
        GROUP BY b.FECHA_COBRO
        """,
        desde, hasta,
    )
    return armar_tramos(periodo, desde, hasta, cursor.fetchall())


@bp.get("/kpis")
@requiere_sesion
def obtener_kpis_del_mes():
    return obtener_kpis("mes")


@bp.get("/kpis/<periodo>")
@requiere_sesion
def obtener_kpis(periodo):
    periodo = periodo.lower()
    if periodo not in PERIODOS:
        opciones = ", ".join(PERIODOS)
        return jsonify({"error": f"Periodo no válido. Usa uno de: {opciones}."}), 400

    desde, hasta, etiqueta = rango_del_periodo(periodo, date.today())

    try:
        conexion = obtener_conexion()
    except NotImplementedError:
        return jsonify({"error": "La conexión a SQL Server todavía no está implementada en core/db.py."}), 503

    cursor = conexion.cursor()
    ingresos = consultar_ingresos(cursor, desde, hasta)

    datos_periodo = {}
    datos_periodo["clave"] = periodo
    datos_periodo["etiqueta"] = etiqueta
    datos_periodo["desde"] = desde.isoformat()
    datos_periodo["hasta"] = hasta.isoformat()

    respuesta = {}
    respuesta["periodo"] = datos_periodo
    respuesta["ingresos"] = ingresos
    respuesta["meta"] = consultar_meta(cursor, desde, hasta, ingresos["cobrado"])
    respuesta["donantesEnRiesgo"] = consultar_riesgo(cursor)
    respuesta["topDiez"] = consultar_top_diez(cursor)
    respuesta["telemarketing"] = consultar_telemarketing(cursor, desde, hasta)
    respuesta["ingresosPorTramo"] = consultar_ingresos_por_tramo(cursor, periodo, desde, hasta)

    return jsonify(respuesta)
