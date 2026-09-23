"""Esquemas del donante — ARCHIVO COMPARTIDO.

Los consumen los blueprints de donantes, resumen y reportes.
Avisa al equipo antes de cambiar los campos.
"""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class Donante(BaseModel):
    id: int
    nombre: str
    segmento: str  # "en_riesgo", "alto_valor"
    estado: str    # "activo", "inactivo"

    montoTotal: Decimal
    ultimaDonacion: datetime
    primeraDonacion: datetime
    frecuencia: str
    montoPromedio: Decimal
    acumulado12Meses: Decimal
    detalleEstado: str
    pagos: list["PagoDonante"] = Field(default_factory=list)
    llamadas: list["LlamadaDonante"] = Field(default_factory=list)


class Donativo(BaseModel):
    id: int
    donante_id: int
    monto: Decimal
    fecha: datetime
    estatus: str  # "cobrado", "rechazado", "pendiente"


class PagoDonante(BaseModel):
    id: int
    date: datetime
    amount: Decimal
    status: str


class LlamadaDonante(BaseModel):
    id: int
    date: datetime
    result: str
    notes: str
