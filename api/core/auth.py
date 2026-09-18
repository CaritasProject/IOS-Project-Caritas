"""Autenticación y permisos — ARCHIVO COMPARTIDO.

Dueño: Persona 1 (Login + Perfil). Los demás blueprints solo aplican el
decorador `requiere_sesion` a sus rutas.
"""

from functools import wraps


def crear_token(datos: dict) -> str:
    """Genera el token JWT de la sesión."""
    # TODO (Persona 1): firmar el token con PyJWT y la configuración de JWT.
    raise NotImplementedError


def usuario_actual():
    """Devuelve el usuario de la petición actual a partir del token."""
    # TODO (Persona 1): leer el encabezado Authorization, validar y devolver.
    raise NotImplementedError


def requiere_sesion(funcion):
    """Decorador que protege una ruta: sin token válido, no pasa."""

    @wraps(funcion)
    def envoltura(*args, **kwargs):
        # TODO (Persona 1): validar el token antes de ejecutar la ruta
        # y responder 401 cuando no sea válido.
        return funcion(*args, **kwargs)

    return envoltura
