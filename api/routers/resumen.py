"""Router del resumen (KPIs de la pantalla de entrada).

Dueño: Persona 2 (Resumen).
"""

from fastapi import APIRouter

router = APIRouter(prefix="/resumen", tags=["resumen"])


@router.get("/kpis")
def obtener_kpis() -> list:
    """KPIs de ingresos, metas, riesgo y telemarketing del periodo."""
    # TODO (Persona 2): consultar SQL Server y devolver los KPIs del periodo.
    return []
