"""Blueprint de metas (avance por línea estratégica).

Dueño: Persona 5 (Metas).
"""

from flask import Blueprint, jsonify

bp = Blueprint("metas", __name__, url_prefix="/metas")


@bp.get("")
def listar_metas():
    """Metas del periodo y su avance."""
    # TODO (Persona 5): consultar SQL Server y devolver las metas del periodo.
    return jsonify([])
