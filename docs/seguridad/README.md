# Seguridad de la API — entregable de ciberseguridad

Equipo 3 "Los Jamones". API en `https://losjamones.tc2007b.tec.mx:10206`.

| Requisito | Estado | Dónde está |
|---|---|---|
| Diseño de integración (tabla de flujos y diagrama) | Hecho | [diseno-integracion.md](diseno-integracion.md) |
| Capa 4: ufw | Hecho en el contenedor de la API: `deny` por defecto, solo entran 22 (SSH), 10206 (API) y dos puertos UDP de administración (123 y 41641). SQL Server está en un contenedor del curso que no administramos (ver R8) | [evidencias/ufw.txt](evidencias/ufw.txt) |
| Capa 5: SSL / HTTPS | Hecho: certificado de la CA del curso, solo TLS 1.2 y 1.3 (TLS 1.0 y 1.1 se rechazan) | `flask run --cert --key` en el contenedor |
| Código seguro: security headers | Hecho en `api/main.py` (`agregar_encabezados`): HSTS, `nosniff`, `X-Frame-Options`, CSP, `Referrer-Policy`, `Permissions-Policy`, `Cross-Origin-Resource-Policy`, `Cache-Control: no-store` | [../../api/main.py](../../api/main.py) |
| Código seguro: Bandit | Hecho: de 8 hallazgos (1 alto) a 1 medio que es un falso positivo documentado | [evidencias/bandit-antes.txt](evidencias/bandit-antes.txt), [evidencias/bandit-despues.txt](evidencias/bandit-despues.txt) |
| Código seguro: OWASP ZAP | Hecho: sin hallazgos altos ni medios; queda 1 bajo (header `Server`, riesgo R10) | [evidencias/zap.html](evidencias/zap.html), [evidencias/zap-primer-escaneo.html](evidencias/zap-primer-escaneo.html) |
| Mínimo privilegio: usuario SQL acotado al esquema | Hecho: `api_caritas` con solo `SELECT/INSERT/UPDATE/DELETE` sobre `dbo` | [../../db/03_usuario_api.sql](../../db/03_usuario_api.sql), [evidencias/usuario-sql.txt](evidencias/usuario-sql.txt) |
| Hashes / SALT-PEPPER | Hecho: scrypt con sal aleatoria por usuario (`werkzeug.security.generate_password_hash`) y pepper: antes del hash la contraseña se mezcla con HMAC-SHA256 y un secreto de 64 caracteres que vive en el `.env`, no en la base | `api/routers/auth.py` (`con_pepper`) |
| JWT y control de sesiones | Hecho: HS256, secreto de 64 caracteres fuera del repo, vigencia de 8 horas, roles por ruta, límite de 5 logins fallidos por minuto por IP | `api/core/auth.py`, `api/main.py` |
| Radar de riesgos (10 o más) | Hecho: 12 riesgos | [radar-riesgos.md](radar-riesgos.md) |

## Bandit

Comando: `bandit -r api -x api/tests`.

| Hallazgo | Antes | Qué se hizo |
|---|---|---|
| B201 `debug=True` en `main.py` (alto) | 1 | Se quitó; `app.run()` queda solo para desarrollo local |
| B104 escuchar en `0.0.0.0` en `main.py` | 1 | Se quitó del arranque local. En el contenedor se escucha en todas las interfaces a propósito y ufw filtra |
| B608 SQL armado con texto en `routers/reportes.py` | 5 | Revisados: solo unen fragmentos fijos del código o nombres de tabla constantes; los valores del usuario van con `?`. Marcados con `# nosec B608` y su motivo |
| B608 en `services/call_service.py:171` | 1 | Mismo caso: `validate_catalog_id` recibe nombres de tabla fijos desde el código. Falso positivo documentado; no se cambió el archivo |

## OWASP ZAP

ZAP 2.17.0 en modo automático (Automation Framework) contra `https://losjamones.tc2007b.tec.mx:10206`, 13/10/2026: se cargaron 22 rutas GET de los tres roles (con su token) y las públicas, luego escaneo pasivo y activo con la política por defecto (inyección SQL, XSS, path traversal, etc.). No se escanearon `POST /auth/login` ni `/auth/registro` para no disparar el límite de intentos ni crear usuarios.

| Hallazgo | Primer escaneo | Escaneo final | Qué se hizo |
|---|---|---|---|
| CSP: directiva sin respaldo (`form-action`) | Medio | — | Se agregó `form-action 'none'` a la `Content-Security-Policy` |
| El header `Server` revela la versión (`Werkzeug/x.y Python/x.y`) | Bajo | Bajo | Lo agrega el servidor de desarrollo de Flask y no se puede quitar desde la app. Riesgo aceptado (R10); se quita al pasar a gunicorn o nginx |
| Revisar las directivas de `Cache-Control` | Informativo | Informativo | Ya se manda `no-store`, que es lo más estricto |
| User Agent Fuzzer | Informativo | Informativo | Solo informa que la respuesta no cambia según el navegador |

## Límite de intentos de login

`api/main.py`, `limitar_intentos_de_login` y `agregar_encabezados`: cada `401` de `/auth/login` se guarda con la hora por IP. Con 5 fallos en los últimos 60 segundos, la siguiente petición responde `429` con `Retry-After: 60` sin consultar la base. Un login correcto nunca se bloquea por sí solo.

## Riesgos que siguen abiertos

Ver [radar-riesgos.md](radar-riesgos.md): R8 (SQL Server compartido con `sa`), R9 (descargas de reportes sin token), R10 (servidor de desarrollo de Flask) y R11 (cuentas de prueba).
