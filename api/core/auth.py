"""Autenticación y permisos — ARCHIVO COMPARTIDO.

Dueño: Persona 1 (Login + Perfil). Los demás blueprints solo aplican el
decorador `requiere_sesion` a sus rutas.
"""

from datetime import datetime, timedelta, timezone
from functools import wraps

import jwt
from flask import g, jsonify, request

from core.config import configuracion


def crear_token(datos: dict) -> str:
    """Genera el token JWT de la sesión.

    `datos` lleva la identidad del usuario (id, correo, rol). Se le agrega la
    fecha de expiración según la configuración.
    """
    ahora = datetime.now(timezone.utc)
    carga = {
        **datos,
        "iat": ahora,
        "exp": ahora + timedelta(minutes=configuracion.jwt_minutos_expiracion),
    }
    return jwt.encode(carga, configuracion.jwt_secreto, algorithm=configuracion.jwt_algoritmo)


def _decodificar_token(token: str) -> dict:
    """Valida la firma y la expiración del token y devuelve su contenido."""
    return jwt.decode(
        token, configuracion.jwt_secreto, algorithms=[configuracion.jwt_algoritmo]
    )


def usuario_actual():
    """Devuelve el usuario de la petición actual a partir del token.

    Lee el encabezado `Authorization: Bearer <token>`. Si no hay token válido
    devuelve None; las rutas protegidas lo traducen a un 401.
    """
    encabezado = request.headers.get("Authorization", "")
    if not encabezado.startswith("Bearer "):
        return None

    token = encabezado.removeprefix("Bearer ").strip()
    try:
        return _decodificar_token(token)
    except jwt.PyJWTError:
        return None


def requiere_sesion(funcion):
    """Decorador que protege una ruta: sin token válido, no pasa."""

    @wraps(funcion)
    def envoltura(*args, **kwargs):
        usuario = usuario_actual()
        if usuario is None:
            return jsonify({"error": "No autorizado. Inicia sesión."}), 401
        # Deja el usuario disponible para la ruta durante esta petición.
        g.usuario = usuario
        return funcion(*args, **kwargs)

    return envoltura


def requiere_rol(*roles_permitidos):
    """Decorador que además exige que el usuario tenga uno de estos roles.

    Uso: @requiere_rol("ADMINISTRADOR"). Sin token -> 401; rol equivocado -> 403.
    """

    def decorador(funcion):
        @wraps(funcion)
        def envoltura(*args, **kwargs):
            usuario = usuario_actual()
            if usuario is None:
                return jsonify({"error": "No autorizado. Inicia sesión."}), 401
            if usuario.get("rol") not in roles_permitidos:
                return jsonify({"error": "No tienes permiso para esta acción."}), 403
            g.usuario = usuario
            return funcion(*args, **kwargs)

        return envoltura

    return decorador
