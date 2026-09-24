from pydantic_settings import BaseSettings, SettingsConfigDict


class Configuracion(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    entorno: str = "desarrollo"
    api_puerto: int = 5000

    sqlserver_host: str = ""
    sqlserver_puerto: int = 1433
    sqlserver_base: str = ""
    sqlserver_usuario: str = ""
    sqlserver_password: str = ""
    sqlserver_driver: str = "ODBC Driver 18 for SQL Server"
    sqlserver_encrypt: str = "yes"
    sqlserver_trust_cert: str = "no"

    jwt_secreto: str = ""
    jwt_algoritmo: str = "HS256"
    jwt_minutos_expiracion: int = 480


configuracion = Configuracion()
