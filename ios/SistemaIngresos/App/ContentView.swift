//
//  ContentView.swift
//  Sistema de Ingresos — Cáritas de Monterrey, A.B.P.
//
//  ARCHIVO COMPARTIDO: navegación principal (TabView con las 5 pestañas).
//  Cada integrante conecta aquí SU pantalla y no toca las de los demás.
//  Avisa al equipo antes de modificarlo.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sesion: SesionService

    // Pestaña seleccionada. Por defecto entra en Resumen.
    @State private var pestanaSeleccionada: Int = 1

    var body: some View {
        // Sin sesión iniciada se ve el login; con sesión, las pestañas.
        if !sesion.sesionIniciada {
            LoginView()
        } else {
            pestanas
        }
    }

    private var pestanas: some View {
        TabView(selection: $pestanaSeleccionada) {

            ResumenView()
                .tabItem {
                    Label("Resumen", systemImage: "house")
                }
                .tag(1)

            DonantesView()
                .tabItem {
                    Label("Donantes", systemImage: "person.2")
                }
                .tag(2)

            ReportesView()
                .tabItem {
                    Label("Reportes", systemImage: "folder")
                }
                .tag(3)

            MetasView()
                .tabItem {
                    Label("Metas", systemImage: "target")
                }
                .tag(4)
        }
        .tint(Palette.turquesa)
    }
}

#Preview {
    ContentView()
        .environmentObject(SesionService())
}
