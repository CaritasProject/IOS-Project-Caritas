//
//  MetaAvance.swift
//  Features / Metas / Model — Hector Fdz
//
//

import SwiftUI

struct MetaAvance: Identifiable, Codable {
    let id: Int
    let nombre: String
    let lineaEstrategica: String
    let objetivo: Double
    let objetivoTotal: Double
    let comprometido: Double
    let cobrado: Double
    let faltante: Double
    let porcentaje: Int
    let semaforo: String
    let donantes: Int
    let agrupacion: String
    let avance: [TramoAvance]

    var color: Color {
        switch semaforo {
        case "verde": Palette.riesgoBajo
        case "amarillo": Palette.riesgoMedio
        default: Palette.riesgoAlto
        }
    }
}

struct TramoAvance: Identifiable, Codable {
    let orden: Int
    let etiqueta: String
    let monto: Double

    var id: Int { return orden }
}

struct Rebanada: Identifiable {
    let id: Int
    let categoria: String
    let valor: Double
}

struct RespuestaMetas: Codable {
    let desde: String
    let hasta: String
    let metas: [MetaAvance]
}

enum Periodo: String, CaseIterable, Identifiable {
    case dia, semana, mes, trimestre, anio

    var id: Self { self }

    var etiqueta: String {
        switch self {
        case .dia: "Día"
        case .semana: "Semana"
        case .mes: "Mes"
        case .trimestre: "Trimestre"
        case .anio: "Año"
        }
    }
}

extension MetaAvance {
    static let muestra: [MetaAvance] = [
        MetaAvance(id: 1, nombre: "Banco De Alimentos", lineaEstrategica: "Telemarketing",
                   objetivo: 820000, objetivoTotal: 820000, comprometido: 742000,
                   cobrado: 664200, faltante: 155800, porcentaje: 81,
                   semaforo: "verde", donantes: 1240, agrupacion: "mensual",
                   avance: [
                       TramoAvance(orden: 1, etiqueta: "Jul", monto: 208400),
                       TramoAvance(orden: 2, etiqueta: "Ago", monto: 221600),
                       TramoAvance(orden: 3, etiqueta: "Sep", monto: 234200)
                   ]),
        MetaAvance(id: 2, nombre: "Dispensarios Médicos", lineaEstrategica: "Eventos",
                   objetivo: 420000, objetivoTotal: 420000, comprometido: 338000,
                   cobrado: 273000, faltante: 147000, porcentaje: 65,
                   semaforo: "amarillo", donantes: 612, agrupacion: "mensual",
                   avance: [
                       TramoAvance(orden: 1, etiqueta: "Jul", monto: 84300),
                       TramoAvance(orden: 2, etiqueta: "Ago", monto: 91200),
                       TramoAvance(orden: 3, etiqueta: "Sep", monto: 97500)
                   ]),
        MetaAvance(id: 4, nombre: "Promoción Humana", lineaEstrategica: "Fundaciones",
                   objetivo: 310000, objetivoTotal: 310000, comprometido: 212400,
                   cobrado: 164300, faltante: 145700, porcentaje: 53,
                   semaforo: "rojo", donantes: 498, agrupacion: "mensual",
                   avance: [
                       TramoAvance(orden: 1, etiqueta: "Jul", monto: 52800),
                       TramoAvance(orden: 2, etiqueta: "Ago", monto: 54100),
                       TramoAvance(orden: 3, etiqueta: "Sep", monto: 57400)
                   ])
    ]
}


