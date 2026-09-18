"""Conexión a SQL Server — ARCHIVO COMPARTIDO.

Todos los routers obtienen la conexión desde aquí.
Avisa al equipo antes de modificarlo.
"""

from core.config import configuracion


def cadena_conexion() -> str:
    """Arma la cadena de conexión a SQL Server a partir de la configuración."""
    # TODO: armar la cadena ODBC y validar que los valores no estén vacíos.
    return ""


def obtener_conexion():
    """Dependencia de FastAPI que entrega una conexión por petición."""
    # TODO: abrir la conexión, cederla con yield y cerrarla al terminar.
    raise NotImplementedError
