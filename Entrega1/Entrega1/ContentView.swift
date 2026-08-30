//
//  ContentView.swift
//  Entrega1
//
//  Created by Ismael Alvarez Rodriguez on 29/08/26.
//

import SwiftUI

// Cuántas capturas tiene el flujo: Cap1, Cap2, ... Cap8
let totalDePantallas = 8

struct ContentView: View {
    // Guarda el camino de pantallas por las que vamos avanzando.
    @State private var ruta: [Int] = []

    var body: some View {
        NavigationStack(path: $ruta) {
            PantallaView(numero: 1, ruta: $ruta)
                .navigationDestination(for: Int.self) { numero in
                    PantallaView(numero: numero, ruta: $ruta)
                }
        }
    }
}

struct PantallaView: View {
    let numero: Int
    @Binding var ruta: [Int]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            // Toda la captura es tocable: avanza a la siguiente pantalla.
            if numero < totalDePantallas {
                NavigationLink(value: numero + 1) {
                    captura
                }
                .buttonStyle(.plain)
            } else {
                captura
            }

            controles
        }
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }

    /// La captura a pantalla completa, sin barras negras.
    var captura: some View {
        Image("Cap\(numero)")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()
    }

    var controles: some View {
        HStack(spacing: 18) {
            Button {
                if !ruta.isEmpty {
                    ruta.removeLast()
                }
            } label: {
                Label("Anterior", systemImage: "chevron.left")
            }
            .disabled(ruta.isEmpty)

            Menu {
                ForEach(1...totalDePantallas, id: \.self) { destino in
                    Button("Pantalla \(destino)") {
                        irA(destino)
                    }
                }
            } label: {
                Text("Pantalla \(numero) de \(totalDePantallas)")
                    .monospacedDigit()
            }

            if numero < totalDePantallas {
                NavigationLink(value: numero + 1) {
                    Label("Siguiente", systemImage: "chevron.right")
                }
            } else {
                Button("Inicio", systemImage: "house") {
                    ruta.removeAll()
                }
            }
        }
        .font(.headline)
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.bottom, 24)
    }

    /// Salta a cualquier pantalla conservando el historial para poder regresar.
    func irA(_ destino: Int) {
        var nuevaRuta: [Int] = []
        if destino > 1 {
            for n in 2...destino {
                nuevaRuta.append(n)
            }
        }
        ruta = nuevaRuta
    }
}

#Preview {
    ContentView()
}
