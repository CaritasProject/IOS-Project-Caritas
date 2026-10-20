import time

from flask import Flask, jsonify, request

from core.config import configuracion
from core.db import cerrar_conexion
from routers.auth import bp as bp_auth
from routers.cobros import bp as bp_cobros
from routers.cobros_del_dia import bp as bp_cobros_del_dia
from routers.donantes import bp as bp_donantes
from routers.llamadas import bp as bp_llamadas
from routers.llamadas_del_dia import bp as bp_llamadas_del_dia
from routers.metas import bp as bp_metas
from routers.reportes import bp as bp_reportes
from routers.resumen import bp as bp_resumen
from routers.visitas import bp as bp_visitas

ENCABEZADOS_SEGUROS = {
    "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'; form-action 'none'",
    "Referrer-Policy": "no-referrer",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
    "Cross-Origin-Resource-Policy": "same-origin",
    "Cache-Control": "no-store",
}

MAX_FALLOS_LOGIN = 5
VENTANA_LOGIN_SEGUNDOS = 60
fallos_login: dict[str, list[float]] = {}


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
    app.register_blueprint(bp_visitas)
    app.register_blueprint(bp_llamadas)
    app.register_blueprint(bp_llamadas_del_dia)
    app.register_blueprint(bp_cobros)
    app.register_blueprint(bp_cobros_del_dia)

    @app.before_request
    def limitar_intentos_de_login():
        if request.path != "/auth/login":
            return None
        ahora = time.time()
        recientes = [t for t in fallos_login.get(request.remote_addr, [])
                     if ahora - t < VENTANA_LOGIN_SEGUNDOS]
        fallos_login[request.remote_addr] = recientes
        if len(recientes) >= MAX_FALLOS_LOGIN:
            respuesta = jsonify({"error": "Demasiados intentos fallidos. Espera un minuto e intenta de nuevo."})
            respuesta.status_code = 429
            respuesta.headers["Retry-After"] = str(VENTANA_LOGIN_SEGUNDOS)
            return respuesta
        return None

    @app.after_request
    def agregar_encabezados(respuesta):
        if request.path == "/auth/login" and respuesta.status_code == 401:
            fallos_login.setdefault(request.remote_addr, []).append(time.time())
        respuesta.headers.update(ENCABEZADOS_SEGUROS)
        return respuesta

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
    # Solo para desarrollo local. En el contenedor se usa `flask run` con --cert y --key.
    app.run(port=configuracion.api_puerto)
