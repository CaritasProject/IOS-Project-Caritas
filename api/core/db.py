"""Conexión a SQL Server — ARCHIVO COMPARTIDO.

Todos los blueprints obtienen la conexión desde aquí.
Avisa al equipo antes de modificarlo.
"""

from flask import g
import pyodbc

from core.config import configuracion


def cadena_conexion() -> str:
    """Arma la cadena de conexión ODBC a SQL Server desde la configuración."""
    required = {
        "SQLSERVER_HOST": configuracion.sqlserver_host,
        "SQLSERVER_BASE": configuracion.sqlserver_base,
        "SQLSERVER_USUARIO": configuracion.sqlserver_usuario,
        "SQLSERVER_PASSWORD": configuracion.sqlserver_password,
    }
    missing = [name for name, value in required.items() if not value]
    if missing:
        raise RuntimeError(f"Faltan variables de conexión: {', '.join(missing)}")

    return ";".join(
        [
            f"DRIVER={{{configuracion.sqlserver_driver}}}",
            f"SERVER={configuracion.sqlserver_host},{configuracion.sqlserver_puerto}",
            f"DATABASE={configuracion.sqlserver_base}",
            f"UID={configuracion.sqlserver_usuario}",
            f"PWD={configuracion.sqlserver_password}",
            f"Encrypt={configuracion.sqlserver_encrypt}",
            f"TrustServerCertificate={configuracion.sqlserver_trust_cert}",
        ]
    )


def obtener_conexion():
    """Devuelve la conexión de la petición actual, creándola la primera vez.

    Se guarda en `g` para que una misma petición reutilice una sola conexión.
    """
    if "conexion" not in g:
        g.conexion = pyodbc.connect(cadena_conexion())
    return g.conexion


def cerrar_conexion(error=None) -> None:
    """Cierra la conexión al terminar la petición. Lo registra main.py."""
    conexion = g.pop("conexion", None)
    if conexion is not None:
        conexion.close()
