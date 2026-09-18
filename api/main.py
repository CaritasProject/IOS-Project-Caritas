"""Sistema de Ingresos — Cáritas de Monterrey, A.B.P.

ARCHIVO COMPARTIDO: crea la aplicación y registra los cinco routers.
Avisa al equipo antes de modificarlo.
"""

from fastapi import FastAPI

from core.config import configuracion
from routers import auth, donantes, metas, reportes, resumen

app = FastAPI(
    title="Sistema de Ingresos",
    description="API del área de Procuración de Fondos de Cáritas de Monterrey.",
    version="0.1.0",
)

app.include_router(auth.router)
app.include_router(resumen.router)
app.include_router(donantes.router)
app.include_router(reportes.router)
app.include_router(metas.router)


@app.get("/salud", tags=["sistema"])
def salud() -> dict:
    """Comprobación rápida de que la API responde."""
    return {"estado": "ok", "entorno": configuracion.entorno}
