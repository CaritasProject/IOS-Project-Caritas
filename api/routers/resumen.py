"""Blueprint del resumen (KPIs de la pantalla de entrada).

Dueño: Persona 2 (Resumen).
"""

from flask import Blueprint, jsonify

bp = Blueprint("resumen", __name__, url_prefix="/resumen")


@bp.get("/kpis")
def obtener_kpis():
    """KPIs de ingresos, metas, riesgo y telemarketing del periodo."""
    # TODO (Persona 2): consultar SQL Server y devolver los KPIs del periodo.
    return jsonify([])
