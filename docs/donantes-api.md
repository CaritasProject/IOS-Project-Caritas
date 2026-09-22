# Integración de Donantes

La pantalla de `Entrega2` está integrada en la pestaña Donantes del proyecto
`ios/SistemaIngresos.xcodeproj` (iOS 17+). La app consulta HTTP mediante
`DonantesService → APIClient`; no carga datos ficticios al ejecutarse.

## Configuración en Xcode

En Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables:

- `API_BASE_URL`: URL base, por defecto `http://localhost:5000`.
- `API_DONANTES_PATH`: prefijo relativo, por defecto `donantes`.
  Si conservas las rutas del prototipo, usa `api/donors`.
- `API_TOKEN`: opcional, se envía como `Authorization: Bearer <token>`.
  No guardes tokens en archivos versionados. El login del repositorio aún no
  proporciona una sesión real; el cliente permite inyectar un proveedor de token.

En un iPad físico usa el nombre local del equipo servidor, por ejemplo
`http://mi-mac.local:5000`, y acepta el permiso de red local. El servidor debe
escuchar en la red local. Usa HTTPS para un servidor remoto. La app permite
red local mediante `NSAllowsLocalNetworking`, sin permitir HTTP arbitrario.
La URL también puede configurarse con la clave `API_BASE_URL` de Info.plist.

## Únicamente dos peticiones

| Método | Ruta predeterminada | Respuesta 200 |
|---|---|---|
| GET | `/donantes` | Arreglo de donantes; `[]` si no hay registros |
| GET | `/donantes/{id}` | Un objeto donante |

Si `API_DONANTES_PATH=api/donors`, las rutas son `/api/donors` y
`/api/donors/{id}`. El JSON esperado es el mismo, independientemente de la ruta.
Búsqueda y filtros son locales: el listado debe devolver todos los registros
(no se implementó paginación). No se necesitan rutas adicionales para pagos o
llamadas, ambos vienen dentro del detalle. La pantalla solo consulta datos.

## Contrato JSON

Consulta el ejemplo completo en `ios/Tests/Fixtures/donantes.json`, adaptado de
los datos de Entrega2. El listado devuelve ese arreglo y el detalle uno de sus
objetos. Todos los campos del ejemplo son obligatorios; usa arreglos vacíos
para pagos y llamadas sin registros. Actualmente el listado y detalle comparten
modelo y estructura completos.

- `id`: entero estable; `nombre`: texto.
- `estado`: `activo` o `inactivo`.
- `segmento`: `general`, `en_riesgo` o `alto_valor`. Estado y segmento son
  independientes: un donante de alto valor también puede estar activo.
- `montoTotal`, `montoPromedio`, `acumulado12Meses`: números JSON en MXN
  (no cadenas con símbolo de moneda); Swift usa `Decimal`.
- `ultimaDonacion`, `primeraDonacion`, y `date` en pagos/llamadas:
  ISO 8601 con zona horaria, por ejemplo `2026-06-12T00:00:00Z`.
- `frecuencia`, `detalleEstado`: texto.
- `pagos`: objetos con `id`, `date`, `amount` y `status`.
  `status`: `cobrado`, `rechazado` o `pendiente`.
- `llamadas`: objetos con `id`, `date`, `result` y `notes`.

Devuelve 404 para un id inexistente, 401 para una sesión inválida y 5xx ante
fallos del servidor. La app muestra errores y permite reintentar; no los
convierte silenciosamente en una lista vacía. La selección descarta respuestas
atrasadas y se ajusta cuando cambia el filtro.

## Alcance pendiente del backend

Por indicación del autor, esta integración no implementa SQL Server ni modifica
los routers. El backend actual solo tiene `GET /donantes` que devuelve `[]`;
`GET /donantes/{id}` debe implementarse en la API que se está creando, junto
con las respuestas del contrato anterior. No hay conexión real verificada aún.

## Verificación

Desde la raíz del repositorio, `bash ios/Tests/run-donantes-tests.sh` comprueba
el cliente y servicio con respuestas HTTP simuladas, sin servidor ni credenciales.
Compila la app con Xcode para comprobar las vistas. Los fixtures son exclusivos
de las pruebas, no forman parte del target de la aplicación.
