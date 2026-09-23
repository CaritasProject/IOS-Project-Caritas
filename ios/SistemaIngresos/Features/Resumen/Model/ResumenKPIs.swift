import Foundation

struct ResumenKPIs: Codable {
    let periodo: PeriodoResumen
    let ingresos: IngresosPeriodo
    let meta: MetaPeriodo
    let donantesEnRiesgo: DonantesEnRiesgo
    let topDiez: TopDiez
    let telemarketing: Telemarketing
    let ingresosPorSemana: [SemanaIngreso]
}

struct PeriodoResumen: Codable {
    let clave: String
    let etiqueta: String
    let desde: String
    let hasta: String
}

struct IngresosPeriodo: Codable {
    let comprometido: Double
    let compromisos: Int
    let cobrado: Double
    let cobrosAplicados: Int
    let porcentajeCobranza: Double
}

struct MetaPeriodo: Codable {
    let montoMeta: Double
    let cobrado: Double
    let porcentaje: Double
}

struct DonantesEnRiesgo: Codable {
    let total: Int
    let criticos: Int
    let moderados: Int
}

struct TopDiez: Codable {
    let total: Int
    let alCorriente: Int
    let porcentajeDeLoCobrado: Double
}

struct Telemarketing: Codable {
    let llamadas: Int
    let compromisosGenerados: Int
    let tasaConversion: Double
}
