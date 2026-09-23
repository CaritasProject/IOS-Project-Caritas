//
//  MetaAvance.swift
//  Features / Metas / Model — Dueño: Persona 5.
//
//  Modelo local de la pantalla. Se llama MetaAvance para no chocar con el
//  modelo compartido Core/Model/Meta.swift.
//  Las llaves son las que devuelve GET /metas del blueprint routers/metas.py.
//

import SwiftUI

struct MetaAvance: Identifiable, Codable {
    let id: Int
    let nombre: String
    let lineaEstrategica: String
    let objetivo: Double        // prorrateado al periodo consultado
    let objetivoTotal: Double   // monto completo de la meta
    let comprometido: Double
    let cobrado: Double
    let faltante: Double
    let porcentaje: Int
    let semaforo: String        // "verde", "amarillo", "rojo"
    let donantes: Int
    let mensual: [MesAvance]

    /// El color del semáforo lo decide la API; aquí solo se traduce a la paleta.
    var color: Color {
        switch semaforo {
        case "verde": Palette.riesgoBajo
        case "amarillo": Palette.riesgoMedio
        default: Palette.riesgoAlto
        }
    }
}

struct MesAvance: Identifiable, Codable {
    let anio: Int
    let mes: Int
    let nombre: String
    let monto: Double

    // Compuesto, no se decodifica: un mes es único dentro de su año.
    var id: String { "\(anio)-\(mes)" }
}

/// Una rebanada de la dona de avance.
struct Rebanada: Identifiable {
    let id: Int
    let categoria: String
    let valor: Double
}

/// Envoltura de GET /metas: el rango consultado más las metas.
struct RespuestaMetas: Codable {
    let desde: String
    let hasta: String
    let metas: [MetaAvance]
}

/// Opciones del Picker. El rawValue es lo que espera la API en la ruta.
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
    /// Solo para #Preview. La pantalla real siempre lee de la API.
    static let muestra: [MetaAvance] = [
        MetaAvance(id: 1, nombre: "Banco De Alimentos", lineaEstrategica: "Telemarketing",
                   objetivo: 820000, objetivoTotal: 820000, comprometido: 742000,
                   cobrado: 664200, faltante: 155800, porcentaje: 81,
                   semaforo: "verde", donantes: 1240,
                   mensual: [
                       MesAvance(anio: 2026, mes: 7, nombre: "Julio", monto: 208400),
                       MesAvance(anio: 2026, mes: 8, nombre: "Agosto", monto: 221600),
                       MesAvance(anio: 2026, mes: 9, nombre: "Septiembre", monto: 234200)
                   ]),
        MetaAvance(id: 2, nombre: "Dispensarios Médicos", lineaEstrategica: "Eventos",
                   objetivo: 420000, objetivoTotal: 420000, comprometido: 338000,
                   cobrado: 273000, faltante: 147000, porcentaje: 65,
                   semaforo: "amarillo", donantes: 612,
                   mensual: [
                       MesAvance(anio: 2026, mes: 7, nombre: "Julio", monto: 84300),
                       MesAvance(anio: 2026, mes: 8, nombre: "Agosto", monto: 91200),
                       MesAvance(anio: 2026, mes: 9, nombre: "Septiembre", monto: 97500)
                   ]),
        MetaAvance(id: 4, nombre: "Promoción Humana", lineaEstrategica: "Fundaciones",
                   objetivo: 310000, objetivoTotal: 310000, comprometido: 212400,
                   cobrado: 164300, faltante: 145700, porcentaje: 53,
                   semaforo: "rojo", donantes: 498,
                   mensual: [
                       MesAvance(anio: 2026, mes: 7, nombre: "Julio", monto: 52800),
                       MesAvance(anio: 2026, mes: 8, nombre: "Agosto", monto: 54100),
                       MesAvance(anio: 2026, mes: 9, nombre: "Septiembre", monto: 57400)
                   ])
    ]
}
