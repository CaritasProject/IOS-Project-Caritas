"""Autenticación y permisos — ARCHIVO COMPARTIDO.

Dueño: Persona 1 (Login + Perfil). Los demás routers solo consumen
`usuario_actual` como dependencia.
"""


def crear_token(datos: dict) -> str:
    """Genera el token JWT de la sesión."""
    # TODO (Persona 1): firmar el token con la configuración de JWT.
    raise NotImplementedError


def usuario_actual():
    """Dependencia que resuelve el usuario a partir del token."""
    # TODO (Persona 1): validar el token y devolver el usuario.
    raise NotImplementedError
