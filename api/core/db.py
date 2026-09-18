"""Conexión a SQL Server — ARCHIVO COMPARTIDO.

Todos los blueprints obtienen la conexión desde aquí.
Avisa al equipo antes de modificarlo.
"""

from flask import g

from core.config import configuracion


def cadena_conexion() -> str:
    """Arma la cadena de conexión ODBC a SQL Server desde la configuración."""
    # TODO: armar la cadena ODBC y validar que los valores no estén vacíos.
    return ""


def obtener_conexion():
    """Devuelve la conexión de la petición actual, creándola la primera vez.

    Se guarda en `g` para que una misma petición reutilice una sola conexión.
    """
    if "conexion" not in g:
        # TODO: abrir la conexión con pyodbc.connect(cadena_conexion()).
        raise NotImplementedError
    return g.conexion


def cerrar_conexion(error=None) -> None:
    """Cierra la conexión al terminar la petición. Lo registra main.py."""
    conexion = g.pop("conexion", None)
    if conexion is not None:
        conexion.close()
