"""Esquemas de metas — ARCHIVO COMPARTIDO.

Los consumen los blueprints de metas, resumen y reportes.

Una meta vive en dbo.META y cuelga de una ASIGNACION (Banco de Alimentos,
Dispensarios Médicos, ...), no de la línea estratégica. La línea que se
reporta es la que más aportó al cobrado dentro del periodo consultado.
"""

from datetime import date
from decimal import Decimal

from pydantic import BaseModel, model_validator

# Periodos que acepta el Picker de la pantalla de Metas (MetasView.swift).
PERIODOS_VALIDOS = ("dia", "semana", "mes", "trimestre", "anio")


class AvanceMensual(BaseModel):
    anio: int
    mes: int
    nombre: str        # "Julio"
    monto: Decimal


class Meta(BaseModel):
    id: int
    nombre: str              # nombre de la asignación
    lineaEstrategica: str
    desde: date              # inicio del traslape entre la meta y el periodo
    hasta: date
    objetivo: Decimal        # prorrateado si el periodo no cubre toda la meta
    objetivoTotal: Decimal   # MONTO_META completo de dbo.META
    comprometido: Decimal
    cobrado: Decimal
    faltante: Decimal
    porcentaje: int
    semaforo: str            # "verde", "amarillo", "rojo"
    donantes: int
    mensual: list[AvanceMensual] = []


class ConsultaMetas(BaseModel):
    """Parámetros de ?periodo= / ?desde= / ?hasta= del GET /metas."""

    periodo: str = "trimestre"
    desde: date | None = None
    hasta: date | None = None

    @model_validator(mode="after")
    def validar(self):
        if (self.desde is None) != (self.hasta is None):
            raise ValueError("desde y hasta se mandan juntos o no se manda ninguno")
        if self.desde and self.hasta and self.hasta < self.desde:
            raise ValueError("la fecha hasta no puede ser anterior a la fecha desde")
        periodo = self.periodo.strip().lower()
        if periodo not in PERIODOS_VALIDOS:
            raise ValueError(
                "el periodo debe ser " + ", ".join(PERIODOS_VALIDOS)
            )
        self.periodo = periodo
        return self
