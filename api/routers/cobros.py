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


CONSULTA_COBROS = """
    SELECT b.ID_BITACORA, b.FECHA_COBRO, b.IMPORTE, e.NOMBRE AS ESTATUS,
           v.HORA_ACORDADA, v.CALLE, v.COLONIA, m.NOMBRE AS MUNICIPIO,
           o.NOMBRE, o.A_PATERNO, o.A_MATERNO, o.RAZON_SOCIAL,
           fp.NOMBRE AS FORMA_PAGO
    FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
    JOIN dbo.VISITA_RECOLECCION v ON v.ID_BITACORA = b.ID_BITACORA
    JOIN dbo.CAT_MUNICIPIO m ON m.ID_MUNICIPIO = v.ID_MUNICIPIO
    JOIN dbo.CAT_ESTATUS_PAGO e ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
    JOIN dbo.OPE_DONATIVOS_DONANTE d ON d.ID_DONATIVO = b.ID_DONATIVO
    JOIN dbo.OPE_DONANTES o ON o.ID_DONANTE = d.ID_DONANTE
    JOIN dbo.CAT_FORMA_PAGO fp ON fp.ID_FORMA_PAGO = d.ID_FORMA_PAGO
"""


def cobro_a_json(fila) -> dict:
    if fila.RAZON_SOCIAL:
        donante = fila.RAZON_SOCIAL
    else:
        donante = f"{fila.NOMBRE} {fila.A_PATERNO} {fila.A_MATERNO or ''}".strip()

    return {
        "id": fila.ID_BITACORA,
        "fecha": fila.FECHA_COBRO.isoformat(),
        "hora": fila.HORA_ACORDADA.strftime("%H:%M"),
        "donante": donante,
        "direccion": f"{fila.CALLE}, {fila.COLONIA}, {fila.MUNICIPIO.title()}",
        "importe": float(fila.IMPORTE),
        "formaPago": fila.FORMA_PAGO.capitalize(),
        "estatus": fila.ESTATUS,
    }


@bp.get("/pendientes")
@requiere_rol("RECOLECTOR")
def listar_pendientes():
    cursor = obtener_conexion().cursor()
    cursor.execute(
        CONSULTA_COBROS
        + """ WHERE e.NOMBRE = N'PENDIENTE'
              ORDER BY b.FECHA_COBRO, v.HORA_ACORDADA""")
    return jsonify([cobro_a_json(fila) for fila in cursor.fetchall()])


@bp.get("/<int:id_cobro>")
@requiere_rol("RECOLECTOR")
def consultar_cobro(id_cobro: int):
    cursor = obtener_conexion().cursor()
    cursor.execute(CONSULTA_COBROS + " WHERE b.ID_BITACORA = ?", id_cobro)
    fila = cursor.fetchone()
    if fila is None:
        return error(f"No existe el cobro {id_cobro}.", 404)
    return jsonify(cobro_a_json(fila))


@bp.get("/<int:id_cobro>/historial")
@requiere_rol("RECOLECTOR")
def consultar_historial(id_cobro: int):
    cursor = obtener_conexion().cursor()
    cursor.execute(
        """SELECT d.ID_DONANTE
           FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
           JOIN dbo.OPE_DONATIVOS_DONANTE d ON d.ID_DONATIVO = b.ID_DONATIVO
           WHERE b.ID_BITACORA = ?""",
        id_cobro)
    cobro = cursor.fetchone()
    if cobro is None:
        return error(f"No existe el cobro {id_cobro}.", 404)

    cursor.execute(
        """SELECT TOP 5 b.ID_BITACORA, b.FECHA_COBRO, b.FECHA_PAGO, b.IMPORTE, b.IMPORTE_COBRADO,
                  e.NOMBRE AS ESTATUS
           FROM dbo.OPE_BITACORA_PAGOS_DONATIVOS b
           JOIN dbo.OPE_DONATIVOS_DONANTE d ON d.ID_DONATIVO = b.ID_DONATIVO
           JOIN dbo.CAT_ESTATUS_PAGO e ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
           WHERE d.ID_DONANTE = ? AND b.ID_BITACORA <> ?
           ORDER BY b.FECHA_COBRO DESC, b.ID_BITACORA DESC""",
        cobro.ID_DONANTE, id_cobro)

    pagos = []
    for fila in cursor.fetchall():
        pagos.append({
            "id": fila.ID_BITACORA,
            "fechaCobro": fila.FECHA_COBRO.isoformat(),
            "fechaPago": fila.FECHA_PAGO.isoformat() if fila.FECHA_PAGO else None,
            "importe": float(fila.IMPORTE),
            "importeCobrado": float(fila.IMPORTE_COBRADO),
            "estatus": fila.ESTATUS,
        })
    return jsonify(pagos)


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
