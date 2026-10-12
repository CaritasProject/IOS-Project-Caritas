from datetime import date

import pyodbc
from flask import Blueprint, g, jsonify, request
from pydantic import ValidationError

from core.auth import requiere_rol, requiere_sesion
from core.db import obtener_conexion
from models.visita import NuevaVisita
from routers.reportes import mensaje_de_validacion

bp = Blueprint("visitas", __name__, url_prefix="/visitas")


def error(mensaje: str, codigo: int):
    return jsonify({"error": mensaje}), codigo


@bp.errorhandler(pyodbc.Error)
def base_no_disponible(_):
    return error("La base de datos no está disponible. Intenta de nuevo.", 503)


@bp.get("/municipios")
@requiere_sesion
def listar_municipios():
    cursor = obtener_conexion().cursor()
    cursor.execute(
        """SELECT m.ID_MUNICIPIO, m.NOMBRE, r.ZONA
           FROM dbo.CAT_MUNICIPIO m
           JOIN dbo.RECOLECTOR r ON r.ID_RECOLECTOR = m.ID_RECOLECTOR
           ORDER BY m.NOMBRE""")
    municipios = []
    for fila in cursor.fetchall():
        municipios.append({"id": fila.ID_MUNICIPIO, "nombre": fila.NOMBRE, "zona": fila.ZONA})
    return jsonify(municipios)


@bp.get("/compromisos/<int:id_donativo>")
@requiere_rol("TELEFONISTA")
def consultar_compromiso(id_donativo: int):
    cursor = obtener_conexion().cursor()
    cursor.execute(
        """SELECT d.ID_DONATIVO, d.IMPORTE, d.PAGO_UNICO,
                  o.NOMBRE, o.A_PATERNO, o.A_MATERNO, o.RAZON_SOCIAL,
                  fp.NOMBRE AS FORMA_PAGO, f.NOMBRE AS FRECUENCIA, tf.NOMBRE AS TIPO_FRECUENCIA
           FROM dbo.OPE_DONATIVOS_DONANTE d
           JOIN dbo.OPE_DONANTES o ON o.ID_DONANTE = d.ID_DONANTE
           JOIN dbo.CAT_FORMA_PAGO fp ON fp.ID_FORMA_PAGO = d.ID_FORMA_PAGO
           LEFT JOIN dbo.CAT_FRECUENCIA f ON f.ID_FRECUENCIA = d.ID_FRECUENCIA
           LEFT JOIN dbo.CAT_TIPO_FRECUENCIA tf ON tf.ID_TIPO_FRECUENCIA = d.ID_TIPO_FRECUENCIA
           WHERE d.ID_DONATIVO = ?""",
        id_donativo)
    compromiso = cursor.fetchone()
    if compromiso is None:
        return error(f"No existe el compromiso {id_donativo}.", 404)

    if compromiso.RAZON_SOCIAL:
        donante = compromiso.RAZON_SOCIAL
    else:
        donante = f"{compromiso.NOMBRE} {compromiso.A_PATERNO} {compromiso.A_MATERNO or ''}".strip()

    if compromiso.PAGO_UNICO:
        frecuencia = "Pago único"
    else:
        frecuencia = f"{compromiso.FRECUENCIA.capitalize()} · {compromiso.TIPO_FRECUENCIA.capitalize()}"

    cursor.execute(
        """SELECT v.ID_VISITA, b.FECHA_COBRO, v.HORA_ACORDADA, r.ZONA
           FROM dbo.VISITA_RECOLECCION v
           JOIN dbo.OPE_BITACORA_PAGOS_DONATIVOS b ON b.ID_BITACORA = v.ID_BITACORA
           JOIN dbo.CAT_ESTATUS_PAGO e ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
           JOIN dbo.RECOLECTOR r ON r.ID_RECOLECTOR = b.ID_RECOLECTOR
           WHERE b.ID_DONATIVO = ? AND e.NOMBRE = N'PENDIENTE'""",
        id_donativo)
    pendiente = cursor.fetchone()
    visita_pendiente = None
    if pendiente is not None:
        visita_pendiente = {
            "id": pendiente.ID_VISITA,
            "fecha": pendiente.FECHA_COBRO.isoformat(),
            "hora": pendiente.HORA_ACORDADA.strftime("%H:%M"),
            "zona": pendiente.ZONA,
        }

    return jsonify({
        "idDonativo": compromiso.ID_DONATIVO,
        "donante": donante,
        "monto": float(compromiso.IMPORTE),
        "formaPago": compromiso.FORMA_PAGO.capitalize(),
        "frecuencia": frecuencia,
        "visitaPendiente": visita_pendiente,
    })


@bp.post("")
@requiere_rol("TELEFONISTA")
def agendar_visita():
    datos = request.get_json(silent=True)
    if datos is None:
        return error("El cuerpo debe ser JSON.", 400)
    try:
        visita = NuevaVisita.model_validate(datos)
    except ValidationError as e:
        return error(mensaje_de_validacion(e.errors()[0]), 400)

    if visita.fecha < date.today():
        return error("La visita debe ser de hoy en adelante.", 400)

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    cursor.execute(
        """SELECT d.IMPORTE, fp.NOMBRE AS FORMA_PAGO
           FROM dbo.OPE_DONATIVOS_DONANTE d
           JOIN dbo.CAT_FORMA_PAGO fp ON fp.ID_FORMA_PAGO = d.ID_FORMA_PAGO
           WHERE d.ID_DONATIVO = ?""",
        visita.idDonativo)
    compromiso = cursor.fetchone()
    if compromiso is None:
        return error(f"No existe el compromiso {visita.idDonativo}.", 404)
    if compromiso.FORMA_PAGO not in ("EFECTIVO", "CHEQUE"):
        return error("Solo los pagos en efectivo o cheque generan una visita de recolección.", 409)

    cursor.execute(
        """SELECT m.ID_RECOLECTOR, r.ZONA
           FROM dbo.CAT_MUNICIPIO m
           JOIN dbo.RECOLECTOR r ON r.ID_RECOLECTOR = m.ID_RECOLECTOR
           WHERE m.ID_MUNICIPIO = ?""",
        visita.idMunicipio)
    municipio = cursor.fetchone()
    if municipio is None:
        return error(f"No existe el municipio {visita.idMunicipio}.", 400)

    cursor.execute(
        """SELECT v.ID_VISITA
           FROM dbo.VISITA_RECOLECCION v
           JOIN dbo.OPE_BITACORA_PAGOS_DONATIVOS b ON b.ID_BITACORA = v.ID_BITACORA
           JOIN dbo.CAT_ESTATUS_PAGO e ON e.ID_ESTATUS_PAGO = b.ESTATUS_PAGO
           WHERE b.ID_DONATIVO = ? AND e.NOMBRE = N'PENDIENTE'""",
        visita.idDonativo)
    if cursor.fetchone() is not None:
        return error("Este compromiso ya tiene una visita pendiente.", 409)

    # El cobro y la visita se guardan juntos: si falla el segundo INSERT no hay commit.
    cursor.execute(
        """INSERT INTO dbo.OPE_BITACORA_PAGOS_DONATIVOS
               (ID_DONATIVO, ID_RECOLECTOR, FECHA_COBRO, FECHA_VENCIMIENTO, IMPORTE, ESTATUS_PAGO)
           OUTPUT INSERTED.ID_BITACORA
           SELECT ?, ?, ?, ?, ?, ID_ESTATUS_PAGO FROM dbo.CAT_ESTATUS_PAGO WHERE NOMBRE = N'PENDIENTE'""",
        visita.idDonativo, municipio.ID_RECOLECTOR, visita.fecha, visita.fecha, compromiso.IMPORTE)
    id_bitacora = cursor.fetchone()[0]

    cursor.execute(
        """INSERT INTO dbo.VISITA_RECOLECCION
               (ID_BITACORA, HORA_ACORDADA, CALLE, COLONIA, ID_MUNICIPIO, ID_USUARIO)
           OUTPUT INSERTED.ID_VISITA
           VALUES (?, ?, ?, ?, ?, ?)""",
        id_bitacora, visita.hora, visita.calle, visita.colonia, visita.idMunicipio, g.usuario["id"])
    id_visita = cursor.fetchone()[0]
    conexion.commit()

    return jsonify({
        "id": id_visita,
        "fecha": visita.fecha.isoformat(),
        "hora": visita.hora.strftime("%H:%M"),
        "zona": municipio.ZONA,
    }), 201
