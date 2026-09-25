from flask import Flask

from core.config import configuracion
from core.db import cerrar_conexion
from routers.auth import bp as bp_auth
from routers.donantes import bp as bp_donantes
from routers.metas import bp as bp_metas
from routers.reportes import bp as bp_reportes
from routers.resumen import bp as bp_resumen


def crear_app() -> Flask:
    app = Flask(__name__)
    app.config["ENTORNO"] = configuracion.entorno
    app.config["JSON_SORT_KEYS"] = False

    # Cierra la conexión a SQL Server al terminar cada petición.
    app.teardown_appcontext(cerrar_conexion)

    app.register_blueprint(bp_auth)
    app.register_blueprint(bp_resumen)
    app.register_blueprint(bp_donantes)
    app.register_blueprint(bp_reportes)
    app.register_blueprint(bp_metas)

    @app.get("/salud")
    def salud():
        return {"estado": "ok", "entorno": configuracion.entorno}

    @app.get("/hello")
    def hello():
        """Ruta de verificación sin protección, para el monitoreo de la clase."""
        return "Sistema de Ingresos - Caritas de Monterrey\n"

    return app


app = crear_app()


if __name__ == "__main__":
    # HTTP (no HTTPS) en desarrollo. host 0.0.0.0 para que un iPad físico en la
    # misma red también pueda conectarse, no solo el simulador.
    app.run(host="0.0.0.0", port=configuracion.api_puerto, debug=True)
