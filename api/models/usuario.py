"""Esquemas del usuario — ARCHIVO COMPARTIDO.

Dueño: Persona 1 (Login + Perfil).
"""

from pydantic import BaseModel, EmailStr


class Usuario(BaseModel):
    id: int
    nombre: str
    correo: EmailStr
    rol: str   # "administrador", "capturista", "consulta"
    area: str  # "Dirección General", "Procuración de Fondos"


class CredencialesEntrada(BaseModel):
    correo: EmailStr
    password: str


class TokenSalida(BaseModel):
    token: str
    tipo: str = "bearer"
