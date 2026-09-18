//
//  Donante.swift
//  Core / Model — ARCHIVO COMPARTIDO.
//  Lo consumen Resumen, Donantes y Reportes. Avisa antes de cambiar los campos.
//

import Foundation

struct Donante: Identifiable, Codable {
    let id: Int
    let nombre: String
    let segmento: String   // "Todos", "En riesgo", "Alto valor"
    let estado: String     // "Activo", "Inactivo"

    // TODO: completar con frecuencia, monto promedio y acumulado 12 meses.
}
