"""Esquema de entrada de Reportes.

Dueño: Persona 4 (Reportes). Las llaves van en camelCase porque son las mismas
que manda la app en ConfiguracionReporte (Reporte.swift).
"""

from datetime import date

from pydantic import BaseModel, field_validator, model_validator

TIPOS_VALIDOS = ("INGRESOS", "COBRANZA", "TELEMARKETING", "METAS")
FORMATOS_VALIDOS = ("PDF", "EXCEL", "CSV")


class ConfiguracionReporte(BaseModel):
    tipo: str
    desde: date                       # "2026-08-01"
    hasta: date
    lineaEstrategica: str = "Todas"   # nombre del catálogo o "Todas"
    campania: str = "Todas"
    formato: str

    @field_validator("tipo")
    @classmethod
    def validar_tipo(cls, valor: str) -> str:
        valor = valor.strip().upper()
        if valor not in TIPOS_VALIDOS:
            raise ValueError("el tipo debe ser Ingresos, Cobranza, Telemarketing o Metas")
        return valor

    @field_validator("formato")
    @classmethod
    def validar_formato(cls, valor: str) -> str:
        valor = valor.strip().upper()
        if valor not in FORMATOS_VALIDOS:
            raise ValueError("el formato debe ser PDF, Excel o CSV")
        return valor

    @model_validator(mode="after")
    def validar_rango(self):
        if self.hasta < self.desde:
            raise ValueError("la fecha hasta no puede ser anterior a la fecha desde")
        return self
