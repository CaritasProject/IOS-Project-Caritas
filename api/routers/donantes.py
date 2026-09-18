"""Blueprint de donantes (listado, ficha, pagos y llamadas).

Dueño: Persona 3 (Donantes).
"""

from flask import Blueprint, jsonify

bp = Blueprint("donantes", __name__, url_prefix="/donantes")


@bp.get("")
def listar_donantes():
    """Listado de donantes filtrable por segmento y estado."""
    # TODO (Persona 3): consultar SQL Server y aplicar los filtros.
    return jsonify([])
