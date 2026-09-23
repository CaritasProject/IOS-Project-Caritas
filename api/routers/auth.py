"""Blueprint de acceso y perfil.

Dueño: Persona 1 (Login + Perfil).

Rutas:
  POST /auth/login    -> valida correo + contraseña y devuelve token + usuario
  GET  /auth/perfil   -> devuelve el usuario de la sesión actual (requiere token)
  GET  /auth/usuarios -> listado de usuarios del sistema (requiere token)
"""

from flask import Blueprint, g, jsonify, request
from werkzeug.security import check_password_hash, generate_password_hash

from core.auth import crear_token, requiere_rol, requiere_sesion
from core.db import obtener_conexion

bp = Blueprint("auth", __name__, url_prefix="/auth")


def _resolver_rol(cursor, rol_entrada):
    """Acepta el ID del rol o su nombre y devuelve el ID, o None si no existe."""
    cursor.execute("SELECT ID_ROL, NOMBRE FROM dbo.CAT_ROL")
    texto = str(rol_entrada).strip()
    for fila in cursor.fetchall():
        if texto == str(fila.ID_ROL) or texto.upper() == fila.NOMBRE.upper():
            return fila.ID_ROL
    return None


def _usuario_a_json(fila) -> dict:
    """Convierte una fila de USUARIO + rol en el JSON que consume la app."""
    return {
        "id": fila.ID_USUARIO,
        "nombre": fila.NOMBRE,
        "correo": fila.CORREO,
        "rol": fila.ROL,
        "area": fila.AREA,
    }


@bp.post("/login")
def login():
    """Valida las credenciales contra SQL Server y entrega un token JWT."""
    datos = request.get_json(silent=True) or {}
    correo = (datos.get("correo") or "").strip().lower()
    password = datos.get("password") or ""

    if not correo or not password:
        return jsonify({"error": "Faltan el correo o la contraseña."}), 400

    conexion = obtener_conexion()
    cursor = conexion.cursor()
    cursor.execute(
        """
        SELECT u.ID_USUARIO, u.NOMBRE, u.CORREO, u.CONTRASENA_HASH,
               u.AREA, r.NOMBRE AS ROL
        FROM dbo.USUARIO u
        JOIN dbo.CAT_ROL r ON r.ID_ROL = u.ID_ROL
        WHERE LOWER(u.CORREO) = ?
        """,
        correo,
    )
    fila = cursor.fetchone()

    # Mismo mensaje si el correo no existe o la contraseña es incorrecta:
    # no revelamos cuál de los dos falló.
    if fila is None or not check_password_hash(fila.CONTRASENA_HASH, password):
        return jsonify({"error": "Correo o contraseña incorrectos."}), 401

    # Deja constancia del acceso.
    cursor.execute(
        "UPDATE dbo.USUARIO SET ULTIMO_ACCESO = SYSDATETIME() WHERE ID_USUARIO = ?",
        fila.ID_USUARIO,
    )
    conexion.commit()

    usuario = _usuario_a_json(fila)
    token = crear_token(
        {"id": usuario["id"], "correo": usuario["correo"], "rol": usuario["rol"]}
    )
    return jsonify({"token": token, "tipo": "bearer", "usuario": usuario})


@bp.post("/registro")
@requiere_rol("ADMINISTRADOR")
def registro():
    """Crea un usuario nuevo. Solo un ADMINISTRADOR con sesión puede hacerlo.

    Cuerpo JSON: { nombre, correo, password, rol, area }
    `rol` acepta el ID (1, 2, 3) o el nombre ("ADMINISTRADOR", "TELEFONISTA"...).
    """
    datos = request.get_json(silent=True) or {}
    nombre = (datos.get("nombre") or "").strip()
    correo = (datos.get("correo") or "").strip().lower()
    password = datos.get("password") or ""
    area = (datos.get("area") or "").strip()
    rol_entrada = datos.get("rol")

    if not nombre or not correo or not password or not area or rol_entrada is None:
        return jsonify(
            {"error": "Faltan datos: nombre, correo, password, rol y area son obligatorios."}
        ), 400
    if len(password) < 6:
        return jsonify({"error": "La contraseña debe tener al menos 6 caracteres."}), 400

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    id_rol = _resolver_rol(cursor, rol_entrada)
    if id_rol is None:
        return jsonify({"error": "El rol indicado no existe."}), 400

    cursor.execute("SELECT ID_USUARIO FROM dbo.USUARIO WHERE LOWER(CORREO) = ?", correo)
    if cursor.fetchone() is not None:
        return jsonify({"error": "Ya existe un usuario con ese correo."}), 409

    # La contraseña se guarda hasheada, nunca en claro.
    cursor.execute(
        """
        INSERT INTO dbo.USUARIO (NOMBRE, CORREO, CONTRASENA_HASH, ID_ROL, AREA)
        OUTPUT INSERTED.ID_USUARIO
        VALUES (?, ?, ?, ?, ?)
        """,
        nombre, correo, generate_password_hash(password), id_rol, area,
    )
    id_nuevo = cursor.fetchone()[0]
    conexion.commit()

    cursor.execute("SELECT NOMBRE FROM dbo.CAT_ROL WHERE ID_ROL = ?", id_rol)
    nombre_rol = cursor.fetchone().NOMBRE

    usuario = {
        "id": id_nuevo,
        "nombre": nombre,
        "correo": correo,
        "rol": nombre_rol,
        "area": area,
    }
    return jsonify(usuario), 201


@bp.get("/perfil")
@requiere_sesion
def perfil():
    """Devuelve el usuario de la sesión activa a partir del token."""
    conexion = obtener_conexion()
    cursor = conexion.cursor()
    cursor.execute(
        """
        SELECT u.ID_USUARIO, u.NOMBRE, u.CORREO, u.AREA, r.NOMBRE AS ROL
        FROM dbo.USUARIO u
        JOIN dbo.CAT_ROL r ON r.ID_ROL = u.ID_ROL
        WHERE u.ID_USUARIO = ?
        """,
        g.usuario["id"],
    )
    fila = cursor.fetchone()
    if fila is None:
        return jsonify({"error": "El usuario ya no existe."}), 404
    return jsonify(_usuario_a_json(fila))


@bp.get("/usuarios")
@requiere_sesion
def listar_usuarios():
    """Listado de usuarios del sistema."""
    conexion = obtener_conexion()
    cursor = conexion.cursor()
    cursor.execute(
        """
        SELECT u.ID_USUARIO, u.NOMBRE, u.CORREO, u.AREA, r.NOMBRE AS ROL
        FROM dbo.USUARIO u
        JOIN dbo.CAT_ROL r ON r.ID_ROL = u.ID_ROL
        ORDER BY u.NOMBRE
        """
    )
    return jsonify([_usuario_a_json(fila) for fila in cursor.fetchall()])
