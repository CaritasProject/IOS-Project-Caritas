import pyodbc
from flask import Blueprint, g, jsonify, request
from core.auth import requiere_rol
from core.db import obtener_conexion
from services.call_service import register_call

bp = Blueprint("calls", __name__)


@bp.get("/llamadas/form-options")
@requiere_rol("TELEFONISTA")
def get_form_options():
    conn = obtener_conexion()
    cursor = conn.cursor()

    try:
        cursor.execute("""
            SELECT ID_FORMA_PAGO, NOMBRE
            FROM dbo.CAT_FORMA_PAGO
            ORDER BY ID_FORMA_PAGO
        """)
        payment_methods = [
            {
                "id": row[0],
                "nombre": row[1]
            }
            for row in cursor.fetchall()
        ]

        cursor.execute("""
            SELECT ID_FRECUENCIA, NOMBRE
            FROM dbo.CAT_FRECUENCIA
            ORDER BY ID_FRECUENCIA
        """)
        frequencies = [
            {
                "id": row[0],
                "nombre": row[1]
            }
            for row in cursor.fetchall()
        ]

        cursor.execute("""
            SELECT ID_TIPO_FRECUENCIA, NOMBRE
            FROM dbo.CAT_TIPO_FRECUENCIA
            ORDER BY ID_TIPO_FRECUENCIA
        """)
        frequency_types = [
            {
                "id": row[0],
                "nombre": row[1]
            }
            for row in cursor.fetchall()
        ]

        return jsonify({
            "formas_pago": payment_methods,
            "frecuencias": frequencies,
            "tipos_frecuencia": frequency_types
        }), 200

    finally:
        cursor.close()

@bp.post("/donantes/<int:donor_id>/llamadas")
@requiere_rol("TELEFONISTA")
def create_call(donor_id):
    data = request.get_json(silent=True)

    if not data:
        return jsonify({
            "error": "El cuerpo de la solicitud es requerido"
        }), 400

    try:
        result = register_call(
            donor_id=donor_id,
            data=data,
            user_id=g.usuario["id"]
        )

        return jsonify(result), 201

    except ValueError as error:
        return jsonify({
            "error": str(error)
        }), 400


@bp.get("/llamadas/donantes/<int:donor_id>")
@requiere_rol("TELEFONISTA")
def get_donor(donor_id):
    conn = obtener_conexion()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            ID_DONANTE,
            COALESCE(
                RAZON_SOCIAL,
                CONCAT_WS(' ', NOMBRE, A_PATERNO, A_MATERNO)
            ) AS NOMBRE_DONANTE
        FROM dbo.OPE_DONANTES
        WHERE ID_DONANTE = ?
    """, donor_id)

    row = cursor.fetchone()

    if row is None:
        cursor.close()

        return jsonify({
            "error": "Donante no encontrado"
        }), 404

    donor = {
        "id": row[0],
        "nombre": row[1]
    }

    cursor.close()

    return jsonify(donor), 200


@bp.errorhandler(pyodbc.Error)
def base_no_disponible(_):
    return jsonify({"error": "La base de datos no está disponible. Intenta de nuevo."}), 503
