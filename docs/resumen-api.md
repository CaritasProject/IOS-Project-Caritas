# Integración de Resumen

La pantalla de Resumen (`ios/SistemaIngresos/Features/Resumen/`) consulta la API
por HTTP mediante `ResumenService → APIClient`. No trae datos de ejemplo: si la
API no responde, la pantalla muestra una alerta con el error.

## Endpoint

| Método | Ruta | Respuesta 200 |
|---|---|---|
| GET | `/resumen/kpis` | KPIs del mes en curso |
| GET | `/resumen/kpis/{periodo}` | KPIs del periodo pedido |

`periodo` es uno de `dia`, `semana`, `mes`, `trimestre`, `ano`. Cualquier otro
valor devuelve **400**. Si `core/db.py` todavía no tiene implementada la conexión
a SQL Server, devuelve **503** con un mensaje explicando eso.

Los cinco valores coinciden con los botones del selector de la barra superior.

## Contrato JSON

```json
{
  "periodo":  { "clave": "mes", "etiqueta": "Agosto 2026",
                "desde": "2026-08-01", "hasta": "2026-08-31" },
  "ingresos": { "comprometido": 2340000.0, "compromisos": 1842,
                "cobrado": 1812400.0, "cobrosAplicados": 1394,
                "porcentajeCobranza": 77.5 },
  "meta":     { "montoMeta": 2400000.0, "cobrado": 1812400.0, "porcentaje": 76.0 },
  "donantesEnRiesgo": { "total": 148, "dosCobrosVencidos": 42, "unCobroVencido": 106 },
  "topDiez":  { "total": 312, "alCorriente": 289, "porcentajeDeLoCobrado": 61.0 },
  "telemarketing": { "llamadas": 4820, "compromisosGenerados": 612,
                     "tasaConversion": 12.7 },
  "ingresosPorTramo": [
    { "orden": 1, "etiqueta": "Sem 31", "comprometido": 430000.0, "cobrado": 352000.0 }
  ]
}
```

Los montos son números JSON en MXN, no cadenas con símbolo de moneda. Los
porcentajes vienen de 0 a 100 con un decimal.

`ingresosPorTramo` trae una barra por tramo del periodo, en orden y con los
tramos sin cobros en cero. `orden` empieza en 1 y es el `id` en iOS.

| Periodo | Tramo | Barras | Etiqueta |
|---|---|---|---|
| `dia` | el día completo | 1 | `24 Sep` |
| `semana` | día, de lunes a domingo | 7 | `Lun 21` |
| `mes`, `trimestre` | semana ISO | 4 a 6 / 13 a 14 | `Sem 36` |
| `ano` | mes | 12 | `Ene` |

El día no se parte en horas porque `FECHA_COBRO` es `DATE`, sin hora. Si
todos los tramos vienen en cero, la app muestra "No hay datos de ingresos para
este periodo." en lugar de la gráfica.

## De dónde sale cada número

Todo se calcula en `api/routers/resumen.py` contra el esquema de `db/01_esquema.sql`.

| Tarjeta | Origen |
|---|---|
| Ingresos del periodo | `OPE_BITACORA_PAGOS_DONATIVOS` filtrada por `FECHA_COBRO`; cobrado suma `IMPORTE_COBRADO` de los que tienen estatus `COBRADO` |
| Metas del periodo | `META` cuyo rango se traslapa con el periodo consultado |
| Donantes en riesgo | `VW_DONANTE_INDICADORES` con `EN_RIESGO = 1`, partido por `COBROS_VENCIDOS` |
| Top 10 % | `VW_DONANTE_INDICADORES` con `ALTO_VALOR = 1`; el porcentaje compara su `ACUMULADO_12_MESES` contra el total |
| Telemarketing | `REGISTRO_LLAMADA` del periodo y compromisos dados de alta en él |
| Gráfica de ingresos | La misma bitácora agrupada por `FECHA_COBRO`; `armar_tramos` la reparte en días, semanas o meses según el periodo |

El semáforo de riesgo y el corte de alto valor no se recalculan aquí: viven en
`VW_DONANTE_INDICADORES`, para que Donantes y Resumen muestren los mismos números.

## Configuración en Xcode

Igual que Donantes, en Product → Scheme → Edit Scheme → Run → Arguments →
Environment Variables:

- `API_BASE_URL`: por defecto `http://localhost:5000`.

## Pendiente

`api/core/db.py` es archivo compartido y todavía no está implementado:
`obtener_conexion()` lanza `NotImplementedError`. Hasta que alguien lo implemente
con `pyodbc`, el endpoint responde 503 y la pantalla muestra esa alerta. Las
consultas SQL ya están escritas contra el esquema real y no dependen de ese
cambio.
