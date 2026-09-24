from datetime import datetime, timedelta, timezone
from functools import wraps

import jwt
from flask import g, jsonify, request

from core.config import configuracion


def crear_token(identidad: dict) -> str:
    ahora = datetime.now(timezone.utc)
    expira = ahora + timedelta(minutes=configuracion.jwt_minutos_expiracion)
    carga = {**identidad, "iat": ahora, "exp": expira}
    return jwt.encode(carga, configuracion.jwt_secreto, algorithm=configuracion.jwt_algoritmo)


def usuario_del_token():
    encabezado = request.headers.get("Authorization", "")
    if not encabezado.startswith("Bearer "):
        return None

    token = encabezado.removeprefix("Bearer ").strip()
    try:
        return jwt.decode(token, configuracion.jwt_secreto, algorithms=[configuracion.jwt_algoritmo])
    except jwt.PyJWTError:
        return None


def requiere_sesion(funcion):
    @wraps(funcion)
    def envoltura(*args, **kwargs):
        usuario = usuario_del_token()
        if usuario is None:
            return jsonify({"error": "No autorizado. Inicia sesión."}), 401
        g.usuario = usuario
        return funcion(*args, **kwargs)

    return envoltura


def requiere_rol(*roles_permitidos):
    def decorador(funcion):
        @wraps(funcion)
        @requiere_sesion
        def envoltura(*args, **kwargs):
            if g.usuario.get("rol") not in roles_permitidos:
                return jsonify({"error": "No tienes permiso para esta acción."}), 403
            return funcion(*args, **kwargs)

        return envoltura

    return decorador
