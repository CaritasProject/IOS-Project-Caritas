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
    app.teardown_appcontext(cerrar_conexion)

    for blueprint in (bp_auth, bp_resumen, bp_donantes, bp_reportes, bp_metas):
        app.register_blueprint(blueprint)

    @app.get("/salud")
    def salud():
        return {"estado": "ok", "entorno": configuracion.entorno}

    @app.get("/hello")
    def hello():
        return "Sistema de Ingresos - Caritas de Monterrey\n"

    return app


app = crear_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=configuracion.api_puerto, debug=True)
