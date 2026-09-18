"""Esquemas de metas — ARCHIVO COMPARTIDO.

Los consumen los blueprints de metas, resumen y reportes.
"""

from decimal import Decimal

from pydantic import BaseModel


class Meta(BaseModel):
    id: int
    linea_estrategica: str  # "Banco de Alimentos", "Dispensarios Médicos", ...
    comprometido: Decimal
    cobrado: Decimal

    # TODO: agregar avance mensual y número de donantes activos.
