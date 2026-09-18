//
//  Palette.swift
//  Core / Utils — ARCHIVO COMPARTIDO.
//  Colores institucionales de Cáritas de Monterrey. No inventes colores fuera de aquí.
//

import SwiftUI

enum Palette {
    /// Turquesa institucional del encabezado y las acciones principales.
    static let turquesa = Color(red: 0.00, green: 0.60, blue: 0.70)

    /// Fondo general de las pantallas.
    static let fondo = Color(red: 0.94, green: 0.95, blue: 0.97)

    /// Superficie de tarjetas y paneles.
    static let superficie = Color.white

    /// Semáforo de riesgo del donante.
    static let riesgoAlto  = Color(red: 0.84, green: 0.19, blue: 0.19)
    static let riesgoMedio = Color(red: 0.96, green: 0.62, blue: 0.04)
    static let riesgoBajo  = Color(red: 0.13, green: 0.70, blue: 0.29)

    // TODO: agregar los tonos secundarios cuando los defina el equipo de diseño.
}
