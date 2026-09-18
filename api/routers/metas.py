"""Router de metas (avance por línea estratégica).

Dueño: Persona 5 (Metas).
"""

from fastapi import APIRouter

router = APIRouter(prefix="/metas", tags=["metas"])


@router.get("")
def listar_metas() -> list:
    """Metas del periodo y su avance."""
    # TODO (Persona 5): consultar SQL Server y devolver las metas del periodo.
    return []
