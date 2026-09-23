#!/bin/sh
# Crea el esquema y carga los datos de prueba en la base local (Docker).
# Requiere el contenedor 'caritas_sqlserver' levantado (docker compose up -d)
# y sqlcmd instalado en el host (brew install mssql-tools18).
set -e

SERVIDOR="localhost,1433"
USUARIO="sa"
PASSWORD="Caritas!2026"
AQUI="$(cd "$(dirname "$0")" && pwd)"

# Busca sqlcmd (mssql-tools18 en Apple Silicon queda en /opt/homebrew/opt).
if command -v sqlcmd >/dev/null 2>&1; then
    SQLCMD="sqlcmd"
elif [ -x /opt/homebrew/opt/mssql-tools18/bin/sqlcmd ]; then
    SQLCMD="/opt/homebrew/opt/mssql-tools18/bin/sqlcmd"
else
    echo "No encuentro sqlcmd. Instálalo con: brew install mssql-tools18"
    exit 1
fi

echo "Esperando a que SQL Server acepte conexiones..."
for intento in $(seq 1 60); do
    if "$SQLCMD" -S "$SERVIDOR" -U "$USUARIO" -P "$PASSWORD" -C -l 3 -Q "SELECT 1" >/dev/null 2>&1; then
        echo "SQL Server responde."
        break
    fi
    sleep 2
done

echo "Creando esquema (01_esquema.sql)..."
"$SQLCMD" -S "$SERVIDOR" -U "$USUARIO" -P "$PASSWORD" -C -b -i "$AQUI/01_esquema.sql"

echo "Cargando datos de prueba (02_datos.sql)..."
"$SQLCMD" -S "$SERVIDOR" -U "$USUARIO" -P "$PASSWORD" -C -b -i "$AQUI/02_datos.sql"

echo "Base de datos SistemaIngresos lista."
