//
//  TarjetaResumen.swift
//  Core / Components — ARCHIVO COMPARTIDO.
//  Tarjeta blanca con título y contenido. La usan Resumen, Metas y Reportes.
//

import SwiftUI

struct TarjetaResumen<Contenido: View>: View {
    let titulo: String
    @ViewBuilder let contenido: () -> Contenido

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titulo)
                .font(.headline)

            contenido()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Palette.superficie)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TarjetaResumen(titulo: "Ingresos del periodo") {
        Text("Contenido de la tarjeta")
    }
    .padding()
    .background(Palette.fondo)
}
