"""Sistema de Ingresos — Cáritas de Monterrey, A.B.P.

ARCHIVO COMPARTIDO: crea la aplicación Flask y registra los cinco blueprints.
Avisa al equipo antes de modificarlo.
"""

from flask import Flask

from core.config import configuracion
from core.db import cerrar_conexion
from routers.auth import bp as bp_auth
from routers.donantes import bp as bp_donantes
from routers.metas import bp as bp_metas
from routers.reportes import bp as bp_reportes
from routers.resumen import bp as bp_resumen


def crear_app() -> Flask:
    """Fábrica de la aplicación: aquí se arma todo y se registran los blueprints."""
    app = Flask(__name__)
    app.config["ENTORNO"] = configuracion.entorno
    app.config["JSON_SORT_KEYS"] = False

    # Cierra la conexión a SQL Server al terminar cada petición.
    app.teardown_appcontext(cerrar_conexion)

    # Un blueprint por pantalla. Cada uno trae su propio url_prefix.
    app.register_blueprint(bp_auth)
    app.register_blueprint(bp_resumen)
    app.register_blueprint(bp_donantes)
    app.register_blueprint(bp_reportes)
    app.register_blueprint(bp_metas)

    @app.get("/salud")
    def salud():
        """Comprobación rápida de que la API responde."""
        return {"estado": "ok", "entorno": configuracion.entorno}

    return app


app = crear_app()


if __name__ == "__main__":
    app.run(debug=True)
