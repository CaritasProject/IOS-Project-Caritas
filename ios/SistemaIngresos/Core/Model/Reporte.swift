import Foundation

struct Reporte: Identifiable, Codable {
    var id: Int
    var nombre: String
    var fecha: String
    var formato: String
    var detalle: String
    var periodicidad: String
    var tipo: String
    var comprometido: Double
    var cobrado: Double

    var meta: String {
        return "\(formato) · \(detalle)"
    }
}

struct ConfiguracionReporte: Codable {
    var tipo: String
    var desde: String
    var hasta: String
    var lineaEstrategica: String
    var campania: String
    var formato: String
}

func reportesDeMuestra() -> [Reporte] {
    return [
        Reporte(id: 1, nombre: "Cobranza semanal · sem 34", fecha: "24 ago 2026",
                formato: "PDF", detalle: "6 páginas", periodicidad: "Semanal",
                tipo: "Cobranza", comprometido: 540000, cobrado: 418900),

        Reporte(id: 2, nombre: "Cobranza semanal · sem 33", fecha: "17 ago 2026",
                formato: "PDF", detalle: "6 páginas", periodicidad: "Semanal",
                tipo: "Cobranza", comprometido: 512000, cobrado: 394300),

        Reporte(id: 3, nombre: "Telemarketing semanal · sem 33", fecha: "17 ago 2026",
                formato: "Excel", detalle: "4 hojas", periodicidad: "Semanal",
                tipo: "Telemarketing", comprometido: 186000, cobrado: 142700),

        Reporte(id: 4, nombre: "Ingresos mensuales · julio", fecha: "01 ago 2026",
                formato: "PDF", detalle: "14 páginas", periodicidad: "Mensual",
                tipo: "Ingresos", comprometido: 2280000, cobrado: 1764500),

        Reporte(id: 5, nombre: "Ingresos mensuales · junio", fecha: "01 jul 2026",
                formato: "PDF", detalle: "14 páginas", periodicidad: "Mensual",
                tipo: "Ingresos", comprometido: 2195000, cobrado: 1702300),

        Reporte(id: 6, nombre: "Avance de metas · segundo trimestre", fecha: "02 jul 2026",
                formato: "Excel", detalle: "3 hojas", periodicidad: "Mensual",
                tipo: "Metas", comprometido: 6480000, cobrado: 5012400)
    ]
}
