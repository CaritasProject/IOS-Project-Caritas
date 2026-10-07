from datetime import date, time
from pydantic import BaseModel, field_validator


class NuevaVisita(BaseModel):
    idDonativo: int
    fecha: date
    hora: time
    calle: str
    colonia: str
    idMunicipio: int

    @field_validator("calle")
    @classmethod
    def validar_calle(cls, valor: str) -> str:
        valor = valor.strip()
        if not valor:
            raise ValueError("captura la calle y el número")
        return valor

    @field_validator("colonia")
    @classmethod
    def validar_colonia(cls, valor: str) -> str:
        valor = valor.strip()
        if not valor:
            raise ValueError("captura la colonia")
        return valor
