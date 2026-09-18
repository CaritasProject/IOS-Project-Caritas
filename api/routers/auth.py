"""Router de acceso y perfil.

Dueño: Persona 1 (Login + Perfil).
"""

from fastapi import APIRouter

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/usuarios")
def listar_usuarios() -> list:
    """Listado de usuarios del sistema."""
    # TODO (Persona 1): consultar SQL Server y devolver los usuarios.
    return []
