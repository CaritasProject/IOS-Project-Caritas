from datetime import date, datetime
from zoneinfo import ZoneInfo

import pyodbc
from flask import Blueprint, jsonify, request

from core.auth import requiere_rol, requiere_sesion
from core.db import obtener_conexion
from routers.cobros import CONSULTA_COBROS, cobro_a_json

bp = Blueprint("cobros_del_dia", __name__)

# Cáritas opera en Monterrey: "hoy" se calcula con su hora, no con la del servidor (UTC).
ZONA_HORARIA = ZoneInfo("America/Monterrey")

DIAS = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
         "agosto", "septiembre", "octubre", "noviembre", "diciembre"]


def error(mensaje: str, codigo: int):
    return jsonify({"error": mensaje}), codigo


@bp.errorhandler(pyodbc.Error)
def base_no_disponible(_):
    return error("La base de datos no está disponible. Intenta de nuevo.", 503)


def fecha_de_hoy() -> date:
    return datetime.now(ZONA_HORARIA).date()


def fecha_en_texto(dia: date) -> str:
    """Ejemplo: 2026-10-02 -> "Viernes, 2 de octubre"."""
    return f"{DIAS[dia.weekday()]}, {dia.day} de {MESES[dia.month - 1]}"


@bp.get("/calendario/hoy")
@requiere_sesion
def consultar_fecha_de_hoy():
    hoy = fecha_de_hoy()
    return jsonify({
        "fecha": hoy.isoformat(),
        "texto": fecha_en_texto(hoy),
    })


@bp.get("/cobros/hoy")
@requiere_rol("RECOLECTOR")
def listar_cobros_de_hoy():
    # ?fecha=YYYY-MM-DD es opcional: sirve para consultar otro día en las pruebas.
    texto_fecha = request.args.get("fecha", "").strip()
    if texto_fecha:
        try:
            dia = date.fromisoformat(texto_fecha)
        except ValueError:
            return error("La fecha debe tener el formato AAAA-MM-DD.", 400)
    else:
        dia = fecha_de_hoy()

    cursor = obtener_conexion().cursor()
    cursor.execute(
        CONSULTA_COBROS
        + """ WHERE e.NOMBRE = N'PENDIENTE' AND b.FECHA_COBRO = ?
              ORDER BY v.HORA_ACORDADA""",
        dia)
    return jsonify([cobro_a_json(fila) for fila in cursor.fetchall()])
