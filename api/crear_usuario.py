import argparse
import getpass
import sys

from core.db import obtener_conexion
from main import app
from routers.auth import LONGITUD_MINIMA_PASSWORD, buscar_rol, correo_registrado, insertar_usuario


def leer_argumentos():
    parser = argparse.ArgumentParser(description="Crea un usuario del sistema.")
    parser.add_argument("--nombre")
    parser.add_argument("--correo")
    parser.add_argument("--rol", help="ID o nombre del rol (ver CAT_ROL)")
    parser.add_argument("--area")
    parser.add_argument("--password", help="Si no lo pones, se pregunta sin mostrarlo")
    return parser.parse_args()


def preguntar_si_falta(pregunta: str, valor) -> str:
    if valor:
        return valor
    return input(pregunta).strip()


def preguntar_rol(cursor) -> str:
    cursor.execute("SELECT ID_ROL, NOMBRE FROM dbo.CAT_ROL ORDER BY ID_ROL")
    print("\nRoles disponibles:")
    for rol in cursor.fetchall():
        print(f"  {rol.ID_ROL} = {rol.NOMBRE}")
    return input("ID del rol: ").strip()


def main() -> int:
    args = leer_argumentos()

    with app.app_context():
        conexion = obtener_conexion()
        cursor = conexion.cursor()

        nombre = preguntar_si_falta("Nombre completo: ", args.nombre)
        correo = preguntar_si_falta("Correo institucional: ", args.correo).lower()
        area = preguntar_si_falta("Área: ", args.area)

        rol = buscar_rol(cursor, args.rol or preguntar_rol(cursor))
        if rol is None:
            print("Ese rol no existe.")
            return 1

        password = args.password or getpass.getpass("Contraseña: ")
        if len(password) < LONGITUD_MINIMA_PASSWORD:
            print(f"La contraseña debe tener al menos {LONGITUD_MINIMA_PASSWORD} caracteres.")
            return 1

        if correo_registrado(cursor, correo):
            print(f"Ya existe un usuario con el correo {correo}.")
            return 1

        id_nuevo = insertar_usuario(cursor, nombre, correo, password, rol.ID_ROL, area)
        conexion.commit()

        print(f"\nUsuario creado: id={id_nuevo}  {nombre}  <{correo}>  rol={rol.NOMBRE}")
        print("Ya puede iniciar sesión con esa contraseña.")
        return 0


if __name__ == "__main__":
    sys.exit(main())
