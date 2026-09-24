from flask import Blueprint, g, jsonify, request
from werkzeug.security import check_password_hash, generate_password_hash

from core.auth import crear_token, requiere_rol, requiere_sesion
from core.db import obtener_conexion

bp = Blueprint("auth", __name__, url_prefix="/auth")

LONGITUD_MINIMA_PASSWORD = 6

CONSULTA_USUARIOS = """
    SELECT u.ID_USUARIO, u.NOMBRE, u.CORREO, u.CONTRASENA_HASH, u.AREA, r.NOMBRE AS ROL
    FROM dbo.USUARIO u
    JOIN dbo.CAT_ROL r ON r.ID_ROL = u.ID_ROL
"""


def error(mensaje: str, codigo: int):
    return jsonify({"error": mensaje}), codigo


def texto(datos: dict, campo: str) -> str:
    return (datos.get(campo) or "").strip()


def buscar_rol(cursor, id_o_nombre):
    cursor.execute("SELECT ID_ROL, NOMBRE FROM dbo.CAT_ROL")
    buscado = str(id_o_nombre).strip().upper()
    for rol in cursor.fetchall():
        if buscado in (str(rol.ID_ROL), rol.NOMBRE.upper()):
            return rol
    return None


def correo_registrado(cursor, correo: str) -> bool:
    cursor.execute("SELECT ID_USUARIO FROM dbo.USUARIO WHERE LOWER(CORREO) = ?", correo)
    return cursor.fetchone() is not None


def insertar_usuario(cursor, nombre: str, correo: str, password: str, id_rol: int, area: str) -> int:
    cursor.execute(
        """
        INSERT INTO dbo.USUARIO (NOMBRE, CORREO, CONTRASENA_HASH, ID_ROL, AREA)
        OUTPUT INSERTED.ID_USUARIO
        VALUES (?, ?, ?, ?, ?)
        """,
        nombre, correo, generate_password_hash(password), id_rol, area,
    )
    return cursor.fetchone()[0]


def usuario_a_json(fila) -> dict:
    return {
        "id": fila.ID_USUARIO,
        "nombre": fila.NOMBRE,
        "correo": fila.CORREO,
        "rol": fila.ROL,
        "area": fila.AREA,
    }


@bp.post("/login")
def login():
    datos = request.get_json(silent=True) or {}
    correo = texto(datos, "correo").lower()
    password = datos.get("password") or ""

    if not correo or not password:
        return error("Faltan el correo o la contraseña.", 400)

    conexion = obtener_conexion()
    cursor = conexion.cursor()
    cursor.execute(CONSULTA_USUARIOS + " WHERE LOWER(u.CORREO) = ?", correo)
    fila = cursor.fetchone()

    credenciales_validas = fila is not None and check_password_hash(fila.CONTRASENA_HASH, password)
    if not credenciales_validas:
        return error("Correo o contraseña incorrectos.", 401)

    cursor.execute(
        "UPDATE dbo.USUARIO SET ULTIMO_ACCESO = SYSDATETIME() WHERE ID_USUARIO = ?",
        fila.ID_USUARIO,
    )
    conexion.commit()

    usuario = usuario_a_json(fila)
    token = crear_token({"id": usuario["id"], "correo": usuario["correo"], "rol": usuario["rol"]})
    return jsonify({"token": token, "tipo": "bearer", "usuario": usuario})


@bp.post("/registro")
@requiere_rol("ADMINISTRADOR")
def registro():
    datos = request.get_json(silent=True) or {}
    nombre = texto(datos, "nombre")
    correo = texto(datos, "correo").lower()
    password = datos.get("password") or ""
    area = texto(datos, "area")
    rol_pedido = datos.get("rol")

    if not nombre or not correo or not password or not area or rol_pedido is None:
        return error("Faltan datos: nombre, correo, password, rol y area son obligatorios.", 400)
    if len(password) < LONGITUD_MINIMA_PASSWORD:
        return error(f"La contraseña debe tener al menos {LONGITUD_MINIMA_PASSWORD} caracteres.", 400)

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    rol = buscar_rol(cursor, rol_pedido)
    if rol is None:
        return error("El rol indicado no existe.", 400)
    if correo_registrado(cursor, correo):
        return error("Ya existe un usuario con ese correo.", 409)

    id_nuevo = insertar_usuario(cursor, nombre, correo, password, rol.ID_ROL, area)
    conexion.commit()

    return jsonify({
        "id": id_nuevo,
        "nombre": nombre,
        "correo": correo,
        "rol": rol.NOMBRE,
        "area": area,
    }), 201


@bp.get("/perfil")
@requiere_sesion
def perfil():
    cursor = obtener_conexion().cursor()
    cursor.execute(CONSULTA_USUARIOS + " WHERE u.ID_USUARIO = ?", g.usuario["id"])
    fila = cursor.fetchone()
    if fila is None:
        return error("El usuario ya no existe.", 404)
    return jsonify(usuario_a_json(fila))


@bp.get("/usuarios")
@requiere_sesion
def listar_usuarios():
    cursor = obtener_conexion().cursor()
    cursor.execute(CONSULTA_USUARIOS + " ORDER BY u.NOMBRE")
    return jsonify([usuario_a_json(fila) for fila in cursor.fetchall()])
