"""Blueprint de acceso y perfil.

Dueño: Persona 1 (Login + Perfil).
"""

from flask import Blueprint, jsonify

bp = Blueprint("auth", __name__, url_prefix="/auth")


@bp.get("/usuarios")
def listar_usuarios():
    """Listado de usuarios del sistema."""
    # TODO (Persona 1): consultar SQL Server y devolver los usuarios.
    return jsonify([])
