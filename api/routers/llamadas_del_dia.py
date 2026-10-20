import pyodbc
from flask import Blueprint, jsonify

from core.auth import usuario_del_token
from core.db import obtener_conexion

bp = Blueprint("llamadas_del_dia", __name__, url_prefix="/llamadas")

RESULTADOS = {
    "PROMESA": "Promesa",
    "NO_CONTESTO": "No contestó",
    "RECHAZO": "Rechazó",
}


def error(mensaje, codigo):
    return jsonify({"error": mensaje}), codigo


@bp.errorhandler(pyodbc.Error)
def base_no_disponible(_):
    return error("La base de datos no está disponible. Intenta de nuevo.", 503)


def nombre_donante(fila):
    if fila.RAZON_SOCIAL:
        return fila.RAZON_SOCIAL
    return f"{fila.NOMBRE} {fila.A_PATERNO} {fila.A_MATERNO or ''}".strip()


@bp.get("/pendientes")
def llamadas_pendientes():
    usuario = usuario_del_token()
    if usuario is None:
        return error("No autorizado. Inicia sesión.", 401)
    if usuario["rol"] != "TELEFONISTA":
        return error("No tienes permiso para esta acción.", 403)

    cursor = obtener_conexion().cursor()
    cursor.execute(
        """SELECT p.ID_PROGRAMADA, p.MOTIVO, d.ID_DONANTE, d.NOMBRE, d.A_PATERNO, d.A_MATERNO,
                  d.RAZON_SOCIAL, d.TELEFONO
           FROM dbo.LLAMADA_PROGRAMADA p
           JOIN dbo.OPE_DONANTES d ON d.ID_DONANTE = p.ID_DONANTE
           WHERE p.ID_USUARIO = ?
             AND p.FECHA <= CAST(GETDATE() AS DATE)
             AND NOT EXISTS (SELECT 1
                             FROM dbo.REGISTRO_LLAMADA r
                             WHERE r.ID_DONANTE = p.ID_DONANTE
                               AND CAST(r.FECHA_LLAMADA AS DATE) >= p.FECHA)
           ORDER BY p.FECHA, p.ID_PROGRAMADA""",
        usuario["id"])
    pendientes = []
    for fila in cursor.fetchall():
        pendientes.append({
            "id": fila.ID_PROGRAMADA,
            "idDonante": fila.ID_DONANTE,
            "donante": nombre_donante(fila),
            "telefono": fila.TELEFONO or "Sin teléfono",
            "motivo": fila.MOTIVO,
        })

    return jsonify(pendientes)


@bp.get("/contactados")
def llamadas_contactadas():
    usuario = usuario_del_token()
    if usuario is None:
        return error("No autorizado. Inicia sesión.", 401)
    if usuario["rol"] != "TELEFONISTA":
        return error("No tienes permiso para esta acción.", 403)

    cursor = obtener_conexion().cursor()
    cursor.execute(
        """SELECT r.ID_LLAMADA, r.RESULTADO, d.ID_DONANTE, d.NOMBRE, d.A_PATERNO, d.A_MATERNO,
                  d.RAZON_SOCIAL, d.TELEFONO
           FROM dbo.REGISTRO_LLAMADA r
           JOIN dbo.OPE_DONANTES d ON d.ID_DONANTE = r.ID_DONANTE
           WHERE r.ID_USUARIO = ?
             AND CAST(r.FECHA_LLAMADA AS DATE) = CAST(GETDATE() AS DATE)
           ORDER BY r.FECHA_LLAMADA DESC""",
        usuario["id"])
    contactados = []
    for fila in cursor.fetchall():
        contactados.append({
            "id": fila.ID_LLAMADA,
            "idDonante": fila.ID_DONANTE,
            "donante": nombre_donante(fila),
            "telefono": fila.TELEFONO or "Sin teléfono",
            "resultado": RESULTADOS.get(fila.RESULTADO, fila.RESULTADO),
        })

    return jsonify(contactados)


@bp.put("/programadas/<int:id_programada>")
def reprogramar_llamada(id_programada):
    usuario = usuario_del_token()
    if usuario is None:
        return error("No autorizado. Inicia sesión.", 401)
    if usuario["rol"] != "TELEFONISTA":
        return error("No tienes permiso para esta acción.", 403)

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    cursor.execute(
        "SELECT ID_DONANTE, FECHA FROM dbo.LLAMADA_PROGRAMADA WHERE ID_PROGRAMADA = ? AND ID_USUARIO = ?",
        id_programada, usuario["id"])
    programada = cursor.fetchone()
    if programada is None:
        return error("La llamada programada no existe.", 404)

    cursor.execute(
        """SELECT TOP 1 RESULTADO
           FROM dbo.REGISTRO_LLAMADA
           WHERE ID_DONANTE = ?
             AND ID_USUARIO = ?
             AND CAST(FECHA_LLAMADA AS DATE) >= ?
           ORDER BY FECHA_LLAMADA DESC""",
        programada.ID_DONANTE, usuario["id"], programada.FECHA)
    llamada = cursor.fetchone()
    if llamada is None:
        return error("Todavía no registras la llamada a este donante.", 400)
    if llamada.RESULTADO != "NO_CONTESTO":
        return error("Solo se reprograman las llamadas que no contestaron.", 400)

    cursor.execute(
        "UPDATE dbo.LLAMADA_PROGRAMADA SET FECHA = DATEADD(DAY, 1, CAST(GETDATE() AS DATE)) WHERE ID_PROGRAMADA = ?",
        id_programada)
    conexion.commit()

    return jsonify({"id": id_programada, "mensaje": "La llamada se reprogramó para mañana."})
