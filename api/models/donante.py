"""Esquemas del donante — ARCHIVO COMPARTIDO.

Los consumen los blueprints de donantes, resumen y reportes.
Avisa al equipo antes de cambiar los campos.
"""

from datetime import date
from decimal import Decimal

from pydantic import BaseModel


class Donante(BaseModel):
    id: int
    nombre: str
    segmento: str  # "en_riesgo", "alto_valor"
    estado: str    # "activo", "inactivo"

    # TODO: agregar frecuencia, monto promedio y acumulado de 12 meses.


class Donativo(BaseModel):
    id: int
    donante_id: int
    monto: Decimal
    fecha: date
    estatus: str  # "cobrado", "rechazado", "pendiente"
