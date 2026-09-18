"""Router de donantes (listado, ficha, pagos y llamadas).

Dueño: Persona 3 (Donantes).
"""

from fastapi import APIRouter

router = APIRouter(prefix="/donantes", tags=["donantes"])


@router.get("")
def listar_donantes() -> list:
    """Listado de donantes filtrable por segmento y estado."""
    # TODO (Persona 3): consultar SQL Server y aplicar los filtros.
    return []
