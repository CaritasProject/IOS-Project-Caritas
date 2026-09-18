//
//  SistemaIngresosApp.swift
//  Sistema de Ingresos — Cáritas de Monterrey, A.B.P.
//
//  ARCHIVO COMPARTIDO: punto de entrada de la app.
//  Avisa al equipo antes de modificarlo.
//

import SwiftUI

@main
struct SistemaIngresosApp: App {
    // Sesión compartida por toda la app.
    // Dueño del servicio: Login + Perfil.
    @StateObject private var sesion = SesionService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sesion)
        }
    }
}
