from datetime import date

import pyodbc
from flask import Blueprint, jsonify

from core.auth import requiere_sesion
from core.db import obtener_conexion
from routers.metas import MESES, ventana_del_periodo

bp = Blueprint("resumen", __name__, url_prefix="/resumen")

PERIODOS = ["dia", "semana", "mes", "trimestre", "ano"]


def etiqueta_del_periodo(periodo: str, desde: date) -> str:
    mes = MESES[desde.month - 1]
    if periodo == "dia":
        return f"{desde.day} de {mes} {desde.year}"
    if periodo == "semana":
        return f"Semana del {desde.day} de {mes}"
    if periodo == "trimestre":
        return f"Trimestre {(desde.month - 1) // 3 + 1} de {desde.year}"
    if periodo == "ano":
        return f"{desde.year}"
    return f"{mes} {desde.year}"


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

    return {
        "comprometido": comprometido,
        "compromisos": fila.COMPROMISOS or 0,
        "cobrado": cobrado,
        "cobrosAplicados": fila.COBROS_APLICADOS or 0,
        "porcentajeCobranza": porcentaje(cobrado, comprometido),
    }


def consultar_meta(cursor, desde, hasta, cobrado):
    cursor.execute(
        """
        SELECT ISNULL(SUM(m.MONTO_META), 0) AS MONTO_META
        FROM dbo.META m
        WHERE m.FECHA_INICIO <= ? AND m.FECHA_FIN >= ?
        """,
        hasta, desde,
    )
    monto_meta = numero(cursor.fetchone().MONTO_META)
    return {
        "montoMeta": monto_meta,
        "cobrado": cobrado,
        "porcentaje": porcentaje(cobrado, monto_meta),
    }


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
    return {
        "total": fila.TOTAL or 0,
        "criticos": fila.CRITICOS or 0,
        "moderados": fila.MODERADOS or 0,
    }


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
    return {
        "total": fila.TOTAL or 0,
        "alCorriente": fila.AL_CORRIENTE or 0,
        "porcentajeDeLoCobrado": porcentaje(fila.APORTADO, fila.TOTAL_12_MESES),
    }


def consultar_telemarketing(cursor, desde, hasta):
    cursor.execute(
        """
        SELECT COUNT(*) AS LLAMADAS
        FROM dbo.REGISTRO_LLAMADA l
        WHERE CAST(l.FECHA_LLAMADA AS DATE) BETWEEN ? AND ?
        """,
        desde, hasta,
    )
    llamadas = cursor.fetchone().LLAMADAS or 0

    cursor.execute(
        """
        SELECT COUNT(*) AS COMPROMISOS
        FROM dbo.OPE_DONATIVOS_DONANTE dv
        WHERE dv.FECHA_ALTA BETWEEN ? AND ?
        """,
        desde, hasta,
    )
    compromisos = cursor.fetchone().COMPROMISOS or 0
    return {
        "llamadas": llamadas,
        "compromisosGenerados": compromisos,
        "tasaConversion": porcentaje(compromisos, llamadas),
    }


def consultar_ingresos_por_semana(cursor, desde, hasta):
    cursor.execute(
        """
        SELECT
            DATEPART(ISO_WEEK, b.FECHA_COBRO)                                          AS SEMANA,
            ISNULL(SUM(b.IMPORTE), 0)                                                  AS COMPROMETIDO,
            ISNULL(SUM(CASE WHEN ep.NOMBRE = N'COBRADO' THEN b.IMPORTE_COBRADO END), 0) AS COBRADO
        FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
        JOIN dbo.CAT_ESTATUS_PAGO ep ON ep.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
        WHERE b.FECHA_COBRO BETWEEN ? AND ?
        GROUP BY DATEPART(ISO_WEEK, b.FECHA_COBRO)
        ORDER BY SEMANA
        """,
        desde, hasta,
    )

    return [
        {
            "semana": fila.SEMANA,
            "etiqueta": f"Sem {fila.SEMANA}",
            "comprometido": numero(fila.COMPROMETIDO),
            "cobrado": numero(fila.COBRADO),
        }
        for fila in cursor.fetchall()
    ]


@bp.errorhandler(pyodbc.Error)
def base_no_disponible(_):
    return jsonify({"error": "La base de datos no está disponible. Intenta de nuevo."}), 503


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

    desde, hasta = ventana_del_periodo(periodo, date.today())
    cursor = obtener_conexion().cursor()
    ingresos = consultar_ingresos(cursor, desde, hasta)

    return jsonify({
        "periodo": {
            "clave": periodo,
            "etiqueta": etiqueta_del_periodo(periodo, desde),
            "desde": desde.isoformat(),
            "hasta": hasta.isoformat(),
        },
        "ingresos": ingresos,
        "meta": consultar_meta(cursor, desde, hasta, ingresos["cobrado"]),
        "donantesEnRiesgo": consultar_riesgo(cursor),
        "topDiez": consultar_top_diez(cursor),
        "telemarketing": consultar_telemarketing(cursor, desde, hasta),
        "ingresosPorSemana": consultar_ingresos_por_semana(cursor, desde, hasta),
    })
