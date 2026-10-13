from datetime import date
from decimal import Decimal
from typing import Literal, Optional

from pydantic import BaseModel, model_validator


class RegistroVisita(BaseModel):
    idCobro: Optional[int] = None
    resultado: Literal["Cobrado", "Donante ausente", "Cancelado"]
    montoCobrado: Optional[Decimal] = None
    fecha: Optional[date] = None

    @model_validator(mode="after")
    def validar_monto(self):
        if self.resultado == "Cobrado":
            if self.montoCobrado is None or self.montoCobrado <= 0:
                raise ValueError("captura el monto cobrado")
        else:
            self.montoCobrado = None
        return self
