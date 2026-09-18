"""Router de reportes (biblioteca, configuración y generación).

Dueño: Persona 4 (Reportes).
"""

from fastapi import APIRouter

router = APIRouter(prefix="/reportes", tags=["reportes"])


@router.get("")
def listar_reportes() -> list:
    """Biblioteca de reportes semanales y mensuales."""
    # TODO (Persona 4): consultar SQL Server y devolver la biblioteca.
    return []
