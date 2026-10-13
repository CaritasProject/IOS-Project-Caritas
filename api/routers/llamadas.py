import pyodbc
from flask import Blueprint, jsonify

from core.auth import usuario_del_token
from core.db import obtener_conexion

bp = Blueprint("llamadas", __name__, url_prefix="/llamadas")

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


def iniciales(nombre):
    letras = ""
    for palabra in nombre.replace(".", " ").split():
        letras = letras + palabra[0].upper()
    return letras[:2]


@bp.get("/hoy")
def llamadas_de_hoy():
    usuario = usuario_del_token()
    if usuario is None:
        return error("No autorizado. Inicia sesión.", 401)
    if usuario["rol"] != "TELEFONISTA":
        return error("No tienes permiso para esta acción.", 403)

    cursor = obtener_conexion().cursor()

    cursor.execute("SELECT NOMBRE FROM dbo.USUARIO WHERE ID_USUARIO = ?", usuario["id"])
    telefonista = cursor.fetchone()
    if telefonista is None:
        return error("El usuario ya no existe.", 404)

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
    por_llamar = []
    for fila in cursor.fetchall():
        por_llamar.append({
            "id": fila.ID_PROGRAMADA,
            "idDonante": fila.ID_DONANTE,
            "donante": nombre_donante(fila),
            "telefono": fila.TELEFONO or "Sin teléfono",
            "motivo": fila.MOTIVO,
        })

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

    return jsonify({
        "iniciales": iniciales(telefonista.NOMBRE),
        "porLlamar": por_llamar,
        "contactados": contactados,
    })
