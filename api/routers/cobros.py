from datetime import date

import pyodbc
from flask import Blueprint, jsonify, request
from pydantic import ValidationError

from core.auth import requiere_rol
from core.db import obtener_conexion
from models.cobro import RegistroVisita
from routers.reportes import mensaje_de_validacion

bp = Blueprint("cobros", __name__, url_prefix="/cobros")


def error(mensaje: str, codigo: int):
    return jsonify({"error": mensaje}), codigo


@bp.errorhandler(pyodbc.Error)
def base_no_disponible(_):
    return error("La base de datos no está disponible. Intenta de nuevo.", 503)


@bp.post("/<int:id_cobro>/visita")
@requiere_rol("RECOLECTOR")
def registrar_visita(id_cobro: int):
    datos = request.get_json(silent=True)
    if datos is None:
        return error("El cuerpo debe ser JSON.", 400)
    try:
        registro = RegistroVisita.model_validate(datos)
    except ValidationError as e:
        return error(mensaje_de_validacion(e.errors()[0]), 400)

    if registro.idCobro is not None and registro.idCobro != id_cobro:
        return error("El cobro de la ruta no coincide con el del cuerpo.", 400)

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    cursor.execute(
        """SELECT v.ID_VISITA, b.IMPORTE, e.NOMBRE AS ESTATUS
           FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
           JOIN dbo.VISITA_RECOLECCION v ON v.ID_BITACORA = b.ID_BITACORA
           JOIN dbo.CAT_ESTATUS_PAGO e ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
           WHERE b.ID_BITACORA = ?""",
        id_cobro)
    cobro = cursor.fetchone()
    if cobro is None:
        return error(f"No existe el cobro {id_cobro}.", 404)
    if cobro.ESTATUS != "PENDIENTE":
        return error("Este cobro ya se registró.", 409)

    if registro.resultado == "Cobrado":
        cursor.execute(
            """UPDATE dbo.OPE_BITACORA_PAGOS_DONATIVOS
               SET ESTATUS_PAGO = (SELECT ID_ESTATUS_PAGO FROM dbo.CAT_ESTATUS_PAGO WHERE NOMBRE = N'COBRADO'),
                   IMPORTE_COBRADO = ?,
                   FECHA_PAGO = ?
               WHERE ID_BITACORA = ?""",
            registro.montoCobrado, date.today(), id_cobro)
    elif registro.resultado == "Cancelado":
        cursor.execute(
            """UPDATE dbo.OPE_BITACORA_PAGOS_DONATIVOS
               SET ESTATUS_PAGO = (SELECT ID_ESTATUS_PAGO FROM dbo.CAT_ESTATUS_PAGO WHERE NOMBRE = N'RECHAZADO')
               WHERE ID_BITACORA = ?""",
            id_cobro)

    conexion.commit()

    return jsonify({
        "id": cobro.ID_VISITA,
        "idCobro": id_cobro,
        "resultado": registro.resultado,
    })
