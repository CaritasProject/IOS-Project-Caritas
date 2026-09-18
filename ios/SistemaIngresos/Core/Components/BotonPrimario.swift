//
//  BotonPrimario.swift
//  Core / Components — ARCHIVO COMPARTIDO.
//  Botón de acción principal (turquesa institucional).
//

import SwiftUI

struct BotonPrimario: View {
    let titulo: String
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Text(titulo)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(Palette.turquesa)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }
}

#Preview {
    BotonPrimario(titulo: "Iniciar sesión") { }
        .padding()
}
