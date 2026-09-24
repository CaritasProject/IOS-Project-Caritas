"""Blueprint de donantes (listado, ficha, pagos y llamadas).

Dueño: Persona 3 (Donantes).
"""

from datetime import date, datetime
from decimal import Decimal

from flask import Blueprint, jsonify

from core.auth import requiere_sesion
from core.db import obtener_conexion


bp = Blueprint("donantes", __name__, url_prefix="/donantes")


BASE_QUERY = """
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


def filas_como_diccionarios(cursor):
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def fila_como_diccionario(cursor):
    columns = [column[0] for column in cursor.description]
    row = cursor.fetchone()
    return dict(zip(columns, row)) if row is not None else None


def iso8601(value):
    if value is None:
        return "0001-01-01T00:00:00Z"
    if isinstance(value, datetime):
        return value.replace(microsecond=0).isoformat() + "Z"
    if isinstance(value, date):
        return value.isoformat() + "T00:00:00Z"
    return str(value)


def numero(value):
    if isinstance(value, Decimal):
        return float(value)
    return float(value or 0)


def segmento(row):
    if row["EN_RIESGO"]:
        return "en_riesgo"
    if row["ALTO_VALOR"]:
        return "alto_valor"
    return "regular"


def detalle_estado(row):
    nivel = row["NIVEL_RIESGO"].lower()
    return f"Nivel de riesgo {nivel} según la última donación"


def serializar_donante(row, pagos=None, llamadas=None):
    return {
        "id": row["ID_DONANTE"],
        "nombre": row["NOMBRE_DONANTE"],
        "segmento": segmento(row),
        "estado": row["ESTATUS_DONANTE"].lower(),
        "nivelRiesgo": row["NIVEL_RIESGO"].lower(),
        "montoTotal": numero(row["MONTO_TOTAL"]),
        "ultimaDonacion": iso8601(row["ULTIMA_DONACION"]),
        "primeraDonacion": iso8601(row["PRIMERA_DONACION"]),
        "frecuencia": row["FRECUENCIA"].capitalize(),
        "montoPromedio": numero(row["MONTO_PROMEDIO"]),
        "acumulado12Meses": numero(row["ACUMULADO_12_MESES"]),
        "detalleEstado": detalle_estado(row),
        "pagos": pagos or [],
        "llamadas": llamadas or [],
    }


@bp.get("")
@requiere_sesion
def listar_donantes():
    """Regresa el listado resumido de donantes."""
    cursor = obtener_conexion().cursor()
    cursor.execute(BASE_QUERY + " ORDER BY i.NOMBRE_DONANTE")
    rows = filas_como_diccionarios(cursor)
    cursor.close()
    return jsonify([serializar_donante(row) for row in rows])


@bp.get("/<int:donante_id>")
@requiere_sesion
def obtener_donante(donante_id):
    """Regresa la ficha, pagos y llamadas de un donante."""
    cursor = obtener_conexion().cursor()
    cursor.execute(BASE_QUERY + " WHERE i.ID_DONANTE = ?", donante_id)
    donor = fila_como_diccionario(cursor)
    if donor is None:
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
            "id": row["ID_BITACORA"],
            "date": iso8601(row["FECHA"]),
            "amount": numero(row["MONTO"]),
            "status": row["ESTATUS"],
        }
        for row in filas_como_diccionarios(cursor)
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
            "id": row["ID_LLAMADA"],
            "date": iso8601(row["FECHA_LLAMADA"]),
            "result": row["RESULTADO"],
            "notes": row["COMENTARIOS"],
        }
        for row in filas_como_diccionarios(cursor)
    ]
    cursor.close()

    return jsonify(serializar_donante(donor, pagos, llamadas))
