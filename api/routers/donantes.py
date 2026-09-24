from datetime import date, datetime

from flask import Blueprint, jsonify

from core.auth import requiere_sesion
from core.db import obtener_conexion


bp = Blueprint("donantes", __name__, url_prefix="/donantes")

CONSULTA_DONANTES = """
SELECT
    i.ID_DONANTE,
    i.NOMBRE_DONANTE,
    i.ESTATUS_DONANTE,
    i.FECHA_ALTA,
    i.ULTIMA_DONACION,
    i.ACUMULADO_12_MESES,
    i.MONTO_PROMEDIO,
    riesgo.NIVEL_RIESGO,
    CAST(CASE WHEN riesgo.NIVEL_RIESGO <> N'VERDE' THEN 1 ELSE 0 END AS BIT) AS EN_RIESGO,
    i.ALTO_VALOR,
    ISNULL(total.MONTO_TOTAL, 0) AS MONTO_TOTAL,
    ISNULL(primera.PRIMERA_DONACION, i.FECHA_ALTA) AS PRIMERA_DONACION,
    ISNULL(frecuencia.FRECUENCIA, N'No especificada') AS FRECUENCIA
FROM dbo.VW_DONANTE_INDICADORES i
CROSS APPLY (
    SELECT CASE
        WHEN i.ULTIMA_DONACION IS NULL THEN N'ROJO'
        WHEN i.ULTIMA_DONACION >= DATEADD(MONTH, -1, CAST(GETDATE() AS DATE)) THEN N'VERDE'
        WHEN i.ULTIMA_DONACION >= DATEADD(MONTH, -6, CAST(GETDATE() AS DATE)) THEN N'AMARILLO'
        WHEN i.ULTIMA_DONACION >= DATEADD(MONTH, -12, CAST(GETDATE() AS DATE)) THEN N'NARANJA'
        ELSE N'ROJO'
    END AS NIVEL_RIESGO
) riesgo
OUTER APPLY (
    SELECT SUM(b.IMPORTE_COBRADO) AS MONTO_TOTAL
    FROM dbo.OPE_DONATIVOS_DONANTE d
    JOIN dbo.OPE_BITACORA_PAGOS_DONATIVOS b ON b.ID_DONATIVO = d.ID_DONATIVO
    JOIN dbo.CAT_ESTATUS_PAGO e ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
    WHERE d.ID_DONANTE = i.ID_DONANTE AND e.NOMBRE = N'COBRADO'
) total
OUTER APPLY (
    SELECT MIN(b.FECHA_PAGO) AS PRIMERA_DONACION
    FROM dbo.OPE_DONATIVOS_DONANTE d
    JOIN dbo.OPE_BITACORA_PAGOS_DONATIVOS b ON b.ID_DONATIVO = d.ID_DONATIVO
    JOIN dbo.CAT_ESTATUS_PAGO e ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
    WHERE d.ID_DONANTE = i.ID_DONANTE AND e.NOMBRE = N'COBRADO'
) primera
OUTER APPLY (
    SELECT TOP 1
        CASE WHEN d.PAGO_UNICO = 1 THEN N'Pago único' ELSE tf.NOMBRE END AS FRECUENCIA
    FROM dbo.OPE_DONATIVOS_DONANTE d
    LEFT JOIN dbo.CAT_TIPO_FRECUENCIA tf ON tf.ID_TIPO_FRECUENCIA = d.ID_TIPO_FRECUENCIA
    WHERE d.ID_DONANTE = i.ID_DONANTE
    ORDER BY CASE WHEN d.ID_ESTATUS = 1 THEN 0 ELSE 1 END, d.FECHA_ALTA DESC
) frecuencia
"""


def nombres_de_columnas(cursor):
    return [columna[0] for columna in cursor.description]


def filas_como_diccionarios(cursor):
    columnas = nombres_de_columnas(cursor)
    return [dict(zip(columnas, fila)) for fila in cursor.fetchall()]


def fila_como_diccionario(cursor):
    columnas = nombres_de_columnas(cursor)
    fila = cursor.fetchone()
    if fila is None:
        return None
    return dict(zip(columnas, fila))


def iso8601(valor):
    if valor is None:
        return "0001-01-01T00:00:00Z"
    if isinstance(valor, datetime):
        return valor.replace(microsecond=0).isoformat() + "Z"
    if isinstance(valor, date):
        return valor.isoformat() + "T00:00:00Z"
    return str(valor)


def numero(valor):
    return float(valor or 0)


def segmento(donante):
    if donante["EN_RIESGO"]:
        return "en_riesgo"
    if donante["ALTO_VALOR"]:
        return "alto_valor"
    return "regular"


def serializar_donante(donante, pagos=None, llamadas=None):
    nivel_riesgo = donante["NIVEL_RIESGO"].lower()
    return {
        "id": donante["ID_DONANTE"],
        "nombre": donante["NOMBRE_DONANTE"],
        "segmento": segmento(donante),
        "estado": donante["ESTATUS_DONANTE"].lower(),
        "nivelRiesgo": nivel_riesgo,
        "montoTotal": numero(donante["MONTO_TOTAL"]),
        "ultimaDonacion": iso8601(donante["ULTIMA_DONACION"]),
        "primeraDonacion": iso8601(donante["PRIMERA_DONACION"]),
        "frecuencia": donante["FRECUENCIA"].capitalize(),
        "montoPromedio": numero(donante["MONTO_PROMEDIO"]),
        "acumulado12Meses": numero(donante["ACUMULADO_12_MESES"]),
        "detalleEstado": f"Nivel de riesgo {nivel_riesgo} según la última donación",
        "pagos": pagos or [],
        "llamadas": llamadas or [],
    }


@bp.get("")
@requiere_sesion
def listar_donantes():
    cursor = obtener_conexion().cursor()
    cursor.execute(CONSULTA_DONANTES + " ORDER BY i.NOMBRE_DONANTE")
    donantes = filas_como_diccionarios(cursor)
    cursor.close()
    return jsonify([serializar_donante(donante) for donante in donantes])


@bp.get("/<int:donante_id>")
@requiere_sesion
def obtener_donante(donante_id):
    cursor = obtener_conexion().cursor()
    cursor.execute(CONSULTA_DONANTES + " WHERE i.ID_DONANTE = ?", donante_id)
    donante = fila_como_diccionario(cursor)
    if donante is None:
        cursor.close()
        return jsonify({"error": "Donante no encontrado"}), 404

    cursor.execute(
        """
        SELECT b.ID_BITACORA, COALESCE(b.FECHA_PAGO, b.FECHA_COBRO) AS FECHA,
               CASE WHEN e.NOMBRE = N'COBRADO' THEN b.IMPORTE_COBRADO ELSE b.IMPORTE END AS MONTO,
               LOWER(e.NOMBRE) AS ESTATUS
        FROM dbo.OPE_DONATIVOS_DONANTE d
        JOIN dbo.OPE_BITACORA_PAGOS_DONATIVOS b ON b.ID_DONATIVO = d.ID_DONATIVO
        JOIN dbo.CAT_ESTATUS_PAGO e ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
        WHERE d.ID_DONANTE = ?
        ORDER BY FECHA DESC, b.ID_BITACORA DESC
        """,
        donante_id,
    )
    pagos = [
        {
            "id": pago["ID_BITACORA"],
            "date": iso8601(pago["FECHA"]),
            "amount": numero(pago["MONTO"]),
            "status": pago["ESTATUS"],
        }
        for pago in filas_como_diccionarios(cursor)
    ]

    cursor.execute(
        """
        SELECT ID_LLAMADA, FECHA_LLAMADA, RESULTADO,
               ISNULL(COMENTARIOS, N'') AS COMENTARIOS
        FROM dbo.REGISTRO_LLAMADA
        WHERE ID_DONANTE = ?
        ORDER BY FECHA_LLAMADA DESC, ID_LLAMADA DESC
        """,
        donante_id,
    )
    llamadas = [
        {
            "id": llamada["ID_LLAMADA"],
            "date": iso8601(llamada["FECHA_LLAMADA"]),
            "result": llamada["RESULTADO"],
            "notes": llamada["COMENTARIOS"],
        }
        for llamada in filas_como_diccionarios(cursor)
    ]
    cursor.close()

    return jsonify(serializar_donante(donante, pagos, llamadas))
