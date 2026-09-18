# Sistema de Ingresos — Cáritas de Monterrey, A.B.P.

App iOS (SwiftUI, iPad Pro horizontal) y API REST en Python para el área de
**Procuración de Fondos**. Vista de **Administrador**. Base de datos: SQL Server.

El repositorio contiene dos cosas distintas:

| Carpeta | Qué es | Estado |
|---|---|---|
| `Entrega1/` | Prototipo navegable: las 8 capturas del flujo encadenadas con `NavigationStack`. Sirve como referencia visual del diseño aprobado. | Terminado, no se modifica |
| `ios/` + `api/` | El proyecto real. Por ahora **solo el esqueleto**: árbol de carpetas, archivos base y configuración de Git. | En construcción, sin lógica de negocio |

---

## 1. Arquitectura

### 1.1 Visión general

Tres piezas, comunicadas en una sola dirección. La app **nunca** habla con la
base de datos: todo pasa por la API.

```
┌────────────────────────┐    HTTP/JSON     ┌────────────────────┐      ODBC      ┌────────────┐
│   App iOS (SwiftUI)    │ ───────────────► │  API REST (Python) │ ─────────────► │ SQL Server │
│   iPad Pro horizontal  │ ◄─────────────── │       Flask        │ ◄───────────── │            │
└────────────────────────┘                  └────────────────────┘                └────────────┘
```

### 1.2 Capas de la app iOS

El dato baja siempre por el mismo camino y **nunca se salta un nivel**:

```
   View  (SwiftUI)          Solo presenta. Sin red, sin JSON, sin SQL.
     │                      Lee estado con @State private var / @EnvironmentObject.
     ▼
   Service  (ObservableObject, @MainActor)
     │                      Pide datos y los expone con @Published.
     │                      Un servicio por Feature: cada dueño manda en el suyo.
     ▼
   APIClient  (Core/Services)
     │                      Único punto de la app que arma peticiones HTTP.
     ▼
   Model  (Core/Model)      Structs Codable: Donante, Donativo, Usuario, Meta.
```

**Reglas de dependencia (quién puede importar a quién):**

- `Features/` **puede** usar `Core/`.
- `Core/` **nunca** conoce una Feature. Si `Core` necesita algo de una pantalla, el diseño está mal.
- Una Feature **nunca** importa otra Feature. Si dos pantallas necesitan lo mismo, sube a `Core/` (ver Regla 2 en §4).
- Una `View` **nunca** instancia `URLSession` ni decodifica JSON. Eso vive en `Services/`.

### 1.3 Capas de la API

```
   routers/     Un Blueprint de Flask por pantalla, con su propio url_prefix.
     │          Define rutas, valida entrada y devuelve JSON.
     ▼
   models/      Esquemas Pydantic: el contrato con la app iOS.
     │
     ▼
   core/        db.py     → conexión a SQL Server (una por petición, en `g`)
                auth.py   → JWT y el decorador `requiere_sesion`
                config.py → lee el .env
```

`main.py` expone la fábrica `crear_app()`: arma la aplicación y registra los
cinco blueprints con `register_blueprint`. No contiene lógica: si estás
escribiendo reglas de negocio ahí, van en tu blueprint.

> La carpeta se sigue llamando `routers/` (así aparece en `CODEOWNERS` y en el
> reparto), pero lo que vive dentro son Blueprints de Flask. Cada archivo expone
> su blueprint con el nombre `bp`.

### 1.4 Correspondencia pantalla ↔ endpoint

Cada pantalla consume su propio prefijo. Así nadie pisa el trabajo de otro:

| Pantalla iOS | Servicio iOS | Prefijo API | Blueprint |
|---|---|---|---|
| Login + Perfil | `LoginService` | `/auth` | `routers/auth.py` |
| Resumen | `ResumenService` | `/resumen` | `routers/resumen.py` |
| Donantes | `DonantesService` | `/donantes` | `routers/donantes.py` |
| Reportes | `ReportesService` | `/reportes` | `routers/reportes.py` |
| Metas | `MetasService` | `/metas` | `routers/metas.py` |

### 1.5 Navegación

`App/ContentView.swift` monta un `TabView` con las cinco pestañas y es el único
lugar donde se enganchan las pantallas. La sesión viaja por `@EnvironmentObject`
desde `SistemaIngresosApp.swift`, para que ninguna pantalla tenga que pedirle el
usuario a otra.

> Nota: el diseño aprobado (`Entrega1/`) usa navegación **lateral** de iPad.
> El esqueleto arranca con `TabView`; migrar a `NavigationSplitView` es un
> cambio contenido en `ContentView.swift` y no afecta ninguna Feature.

### 1.6 Árbol del proyecto

```
ios/SistemaIngresos/
  App/          SistemaIngresosApp.swift, ContentView.swift      <- COMPARTIDO
  Core/
    Model/      Donante, Donativo, Usuario, Meta                 <- COMPARTIDO
    Services/   APIClient, SesionService                         <- COMPARTIDO
    Components/ SemaforoRiesgo, TarjetaResumen, BotonPrimario    <- COMPARTIDO
    Utils/      Palette, Formatos                                <- COMPARTIDO
  Features/
    Login/      Views/ Services/                                 <- Persona 1
    Resumen/    Views/ Components/ Services/                     <- Persona 2
    Donantes/   Views/ Components/ Services/                     <- Persona 3
    Reportes/   Views/ Components/ Services/                     <- Persona 4
    Metas/      Views/ Components/ Services/                     <- Persona 5

api/
  main.py            crear_app() y los 5 blueprints              <- COMPARTIDO
  requirements.txt                                               <- COMPARTIDO
  .env.example       plantilla de conexión (sin valores reales)
  core/              db.py, auth.py, config.py                   <- COMPARTIDO
  models/            donante.py, usuario.py, meta.py             <- COMPARTIDO
  routers/           blueprints: auth, resumen, donantes, ...    <- uno por persona
```

---

## 2. Reparto por persona

Cada integrante es dueño de **una pantalla** y de **los endpoints que esa
pantalla necesita**. Nadie más toca esos archivos.

| Persona | Pantalla | Carpeta iOS | Blueprint API |
|---|---|---|---|
| Persona 1 | Login + Perfil | `ios/SistemaIngresos/Features/Login/` | `api/routers/auth.py` (y `api/core/auth.py`) |
| Persona 2 | Resumen | `ios/SistemaIngresos/Features/Resumen/` | `api/routers/resumen.py` |
| Persona 3 | Donantes | `ios/SistemaIngresos/Features/Donantes/` | `api/routers/donantes.py` |
| Persona 4 | Reportes | `ios/SistemaIngresos/Features/Reportes/` | `api/routers/reportes.py` |
| Persona 5 | Metas | `ios/SistemaIngresos/Features/Metas/` | `api/routers/metas.py` |

> Sustituyan «Persona N» por los nombres reales y actualicen también
> `.github/CODEOWNERS` con los usuarios de GitHub de cada quien.

---

## 3. Archivos compartidos: avisa antes de tocarlos

Estos archivos los usan **todas** las pantallas. Si necesitas cambiar uno:
avisa en el grupo, explica qué cambias y por qué, y espera confirmación antes
de hacer merge. Un cambio silencioso aquí rompe el trabajo de los otros cuatro.

**iOS**

- `App/SistemaIngresosApp.swift` — punto de entrada de la app.
- `App/ContentView.swift` — `TabView` con las 5 pestañas.
- `Core/Model/` — `Donante.swift`, `Donativo.swift`, `Usuario.swift`, `Meta.swift`.
- `Core/Services/` — `APIClient.swift`, `SesionService.swift`.
- `Core/Components/` — `SemaforoRiesgo.swift`, `TarjetaResumen.swift`, `BotonPrimario.swift`.
- `Core/Utils/` — `Palette.swift`, `Formatos.swift`.
- El archivo `.pbxproj` del proyecto de Xcode (se fusiona por unión, ver §6).

**API**

- `api/main.py` — `crear_app()` y el registro de los 5 blueprints.
- `api/core/` — `db.py`, `auth.py`, `config.py`.
- `api/models/` — `donante.py`, `usuario.py`, `meta.py`.
- `api/requirements.txt`.

**Repositorio**

- `README.md`, `.gitignore`, `.gitattributes`, `.github/CODEOWNERS`.
- `Entrega1/` — prototipo ya entregado: se conserva como referencia y no se modifica.

---

## 4. Reglas de trabajo en equipo

**Regla 1 — Nadie edita la carpeta de otro.**
Si tu pantalla necesita algo que vive en la carpeta de otra persona, se lo pides;
no lo cambias tú. Esto aplica igual a las Features de iOS y a los routers de la API.

**Regla 2 — Un componente sube a `Core/Components/` solo cuando dos features lo necesitan.**
Mientras lo use una sola pantalla, vive en `Features/<TuPantalla>/Components/`.
Cuando una segunda pantalla lo necesite, entre las dos personas lo mueven a
`Core/Components/` y lo avisan al equipo. No se sube «por si acaso».

**Regla 3 — Avisa antes de tocar un archivo compartido** (la lista de §3).

**Regla 4 — Una rama por pantalla.**
`feature/login`, `feature/resumen`, `feature/donantes`, `feature/reportes`,
`feature/metas`. Pull Request a `main` con revisión de la persona que aparezca
en `CODEOWNERS`.

---

## 5. Convenciones de código

**Swift / SwiftUI**

- Estado local siempre con `@State private var`.
- Selectores con `Picker(selection:label:)`.
- Imágenes escalables con `.resizable(resizingMode: .stretch)`.
- **Nunca** `!` para desempaquetar: usa `if let` (o `guard let`).
- **Nunca** instancies `URLSession` dentro del `body` de una `View`.
- **Nunca** decodifiques JSON en una pantalla: eso vive en `Services/`.
- Textos de interfaz **en español**, sin mezclar idiomas.

**Python / API**

- Un `Blueprint` por pantalla, con su `url_prefix`, exportado como `bp`.
- Los esquemas de entrada y salida son modelos Pydantic en `models/`.
- Devuelve JSON con `jsonify(...)`; nada de `render_template`: esto es una API.
- La conexión a SQL Server se obtiene siempre desde `core/db.py` (vive en `g`
  y se cierra sola al terminar la petición). Nunca abras `pyodbc.connect` en
  una ruta.
- Las rutas que requieren sesión llevan el decorador `@requiere_sesion`.
- Las credenciales van en `.env` (nunca en el código; ver `.env.example`).

---

## 6. Puesta en marcha

**API**

```bash
cd api
python -m venv venv
venv\Scripts\activate        # Windows
pip install -r requirements.txt
copy .env.example .env       # y llena los valores reales
flask --app main run --debug
```

La API queda en <http://localhost:5000>; para comprobar que responde:
<http://localhost:5000/salud>

**iOS**

Abre el proyecto en Xcode y ejecuta sobre el simulador de **iPad Pro en horizontal**.

**Nota sobre el `.pbxproj`:** `.gitattributes` lo marca como `merge=union`, lo
que reduce los conflictos cuando dos personas agregan archivos al proyecto al
mismo tiempo. Si aun así Xcode se queja después de un merge, revisa que no haya
líneas duplicadas en el archivo antes de volver a abrir el proyecto.
