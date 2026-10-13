from math import isfinite

from core.db import obtener_conexion


VALID_RESULTS = {"PROMESA", "NO_CONTESTO", "RECHAZO"}


def register_call(donor_id, data, user_id):
    if not isinstance(data, dict):
        raise ValueError("El cuerpo debe ser un objeto JSON")
    resultado = data.get("resultado")
    comentarios = data.get("comentarios")
    compromiso = data.get("compromiso")

    if not isinstance(resultado, str) or resultado not in VALID_RESULTS:
        raise ValueError("Resultado de llamada inválido")

    if resultado == "PROMESA" and compromiso is None:
        raise ValueError(
            "Una promesa debe incluir los datos del compromiso"
        )

    if comentarios is not None and not isinstance(comentarios, str):
        raise ValueError("Los comentarios deben ser texto")
    if resultado == "PROMESA" and not isinstance(compromiso, dict):
        raise ValueError("El compromiso debe ser un objeto JSON")
    if resultado != "PROMESA" and compromiso is not None:
        raise ValueError("Solo una promesa puede incluir un compromiso")

    conn = obtener_conexion()
    cursor = conn.cursor()

    try:
        cursor.execute("SELECT 1 FROM dbo.OPE_DONANTES WHERE ID_DONANTE = ?", donor_id)
        if cursor.fetchone() is None:
            raise ValueError("Donante no encontrado")

        cursor.execute("""
            INSERT INTO dbo.REGISTRO_LLAMADA (
                ID_DONANTE,
                ID_USUARIO,
                FECHA_LLAMADA,
                RESULTADO,
                COMENTARIOS
            )
            OUTPUT INSERTED.ID_LLAMADA
            VALUES (?, ?, SYSDATETIME(), ?, ?)
        """, (
            donor_id,
            user_id,
            resultado,
            comentarios
        ))

        call_id = cursor.fetchone()[0]

        commitment_id = None

        if resultado == "PROMESA":
            commitment_id = create_commitment(
                cursor,
                donor_id,
                compromiso
            )

        conn.commit()

        return {
            "id_llamada": call_id,
            "id_donativo": commitment_id
        }

    except Exception:
        conn.rollback()
        raise

    finally:
        cursor.close()

def create_commitment(cursor, donor_id, data):
    importe = data.get("importe")
    payment_method = data.get("id_forma_pago")
    single_payment = data.get("pago_unico")
    frequency = data.get("id_frecuencia")
    frequency_type = data.get("id_tipo_frecuencia")

    if isinstance(importe, bool) or not isinstance(importe, (int, float)) or not isfinite(importe) or importe <= 0:
        raise ValueError("El importe debe ser mayor que cero")

    if payment_method is None:
        raise ValueError("La forma de pago es requerida")

    if not isinstance(single_payment, bool):
        raise ValueError("pago_unico debe ser verdadero o falso")

    validate_catalog_id(
        cursor,
        "dbo.CAT_FORMA_PAGO",
        "ID_FORMA_PAGO",
        payment_method,
        "La forma de pago no existe"
    )

    if single_payment:
        frequency = None
        frequency_type = None
    else:
        if frequency is None or frequency_type is None:
            raise ValueError(
                "La frecuencia y el tipo de frecuencia son requeridos"
            )

        validate_catalog_id(
            cursor,
            "dbo.CAT_FRECUENCIA",
            "ID_FRECUENCIA",
            frequency,
            "La frecuencia no existe"
        )
        validate_catalog_id(
            cursor,
            "dbo.CAT_TIPO_FRECUENCIA",
            "ID_TIPO_FRECUENCIA",
            frequency_type,
            "El tipo de frecuencia no existe"
        )

    cursor.execute("""
        SELECT ID_ESTATUS
        FROM dbo.CAT_ESTATUS_DONATIVO
        WHERE UPPER(NOMBRE) = N'ACTIVO'
    """)
    status_row = cursor.fetchone()

    if status_row is None:
        raise ValueError("No existe el estatus ACTIVO para el donativo")

    cursor.execute("""
        INSERT INTO dbo.OPE_DONATIVOS_DONANTE (
            ID_DONANTE,
            IMPORTE,
            ID_FORMA_PAGO,
            ID_FRECUENCIA,
            ID_TIPO_FRECUENCIA,
            PAGO_UNICO,
            ID_LINEA_ESTRATEGICA,
            ID_ASIGNACION,
            ID_ESTATUS,
            FECHA_ALTA
        )
        OUTPUT INSERTED.ID_DONATIVO
        VALUES (?, ?, ?, ?, ?, ?, 1, 1, ?, SYSDATETIME())
    """, (
        donor_id,
        importe,
        payment_method,
        frequency,
        frequency_type,
        single_payment,
        status_row[0]
    ))

    return cursor.fetchone()[0]


def validate_catalog_id(cursor, table, column, value, error_message):
    if type(value) is not int or value <= 0:
        raise ValueError(error_message)
    cursor.execute(
        f"SELECT 1 FROM {table} WHERE {column} = ?",
        value
    )

    if cursor.fetchone() is None:
        raise ValueError(error_message)
