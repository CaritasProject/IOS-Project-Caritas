"""Alta de usuarios del sistema — herramienta de línea de comandos.

Crea un usuario con su contraseña hasheada (scrypt, igual que el seed).
La contraseña NUNCA se guarda en texto plano: solo se guarda el hash.

Uso interactivo (te pregunta todo):
    python crear_usuario.py

Uso directo (todo por argumentos):
    python crear_usuario.py --nombre "Ana López" --correo ana@caritas.org.mx \\
        --rol 2 --area "Procuración de Fondos" --password "SuClave123"
"""

import argparse
import getpass
import sys

from werkzeug.security import generate_password_hash

from core.db import obtener_conexion
from main import app


def listar_roles(cursor) -> dict:
    """Devuelve {id: nombre} de los roles disponibles."""
    cursor.execute("SELECT ID_ROL, NOMBRE FROM dbo.CAT_ROL ORDER BY ID_ROL")
    return {fila.ID_ROL: fila.NOMBRE for fila in cursor.fetchall()}


def pedir(texto: str, valor) -> str:
    """Usa el valor dado o lo pregunta si viene vacío."""
    if valor:
        return valor
    return input(texto).strip()


def main() -> int:
    parser = argparse.ArgumentParser(description="Crea un usuario del sistema.")
    parser.add_argument("--nombre")
    parser.add_argument("--correo")
    parser.add_argument("--rol", type=int, help="ID del rol (ver CAT_ROL)")
    parser.add_argument("--area")
    parser.add_argument("--password", help="Si no lo pones, se pregunta oculto")
    args = parser.parse_args()

    # Todo corre dentro del contexto de la app para reutilizar la conexión.
    with app.app_context():
        conexion = obtener_conexion()
        cursor = conexion.cursor()

        roles = listar_roles(cursor)

        nombre = pedir("Nombre completo: ", args.nombre)
        correo = pedir("Correo institucional: ", args.correo).lower()
        area = pedir("Área: ", args.area)

        rol = args.rol
        if not rol:
            print("\nRoles disponibles:")
            for id_rol, nombre_rol in roles.items():
                print(f"  {id_rol} = {nombre_rol}")
            rol = int(input("ID del rol: ").strip())

        if rol not in roles:
            print(f"El rol {rol} no existe. Opciones: {list(roles)}")
            return 1

        password = args.password or getpass.getpass("Contraseña: ")
        if len(password) < 6:
            print("La contraseña debe tener al menos 6 caracteres.")
            return 1

        # ¿Ya existe el correo?
        cursor.execute("SELECT ID_USUARIO FROM dbo.USUARIO WHERE LOWER(CORREO) = ?", correo)
        if cursor.fetchone() is not None:
            print(f"Ya existe un usuario con el correo {correo}.")
            return 1

        hash_contrasena = generate_password_hash(password)

        cursor.execute(
            """
            INSERT INTO dbo.USUARIO (NOMBRE, CORREO, CONTRASENA_HASH, ID_ROL, AREA)
            OUTPUT INSERTED.ID_USUARIO
            VALUES (?, ?, ?, ?, ?)
            """,
            nombre, correo, hash_contrasena, rol, area,
        )
        id_nuevo = cursor.fetchone()[0]
        conexion.commit()

        print(f"\nUsuario creado: id={id_nuevo}  {nombre}  <{correo}>  rol={roles[rol]}")
        print("Ya puede iniciar sesión con esa contraseña.")
        return 0


if __name__ == "__main__":
    sys.exit(main())
