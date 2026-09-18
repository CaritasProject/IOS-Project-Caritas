"""Blueprint de reportes (biblioteca, configuración y generación).

Dueño: Persona 4 (Reportes).
"""

from flask import Blueprint, jsonify

bp = Blueprint("reportes", __name__, url_prefix="/reportes")


@bp.get("")
def listar_reportes():
    """Biblioteca de reportes semanales y mensuales."""
    # TODO (Persona 4): consultar SQL Server y devolver la biblioteca.
    return jsonify([])
