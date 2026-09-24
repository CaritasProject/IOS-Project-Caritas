import SwiftUI

struct GraficaIngresos: View {
    let titulo: String
    let tramos: [TramoIngreso]
    let alturaMaxima: Double

    private var maximo: Double {
        var mayor = 1.0
        for tramo in tramos {
            if tramo.comprometido > mayor { mayor = tramo.comprometido }
            if tramo.cobrado > mayor { mayor = tramo.cobrado }
        }
        return mayor
    }

    /// La API manda todos los tramos del periodo, aunque estén en cero.
    /// Si ninguno tiene montos, no hay nada que graficar.
    private var hayDatos: Bool {
        for tramo in tramos {
            if tramo.comprometido > 0 || tramo.cobrado > 0 { return true }
        }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(titulo)
                    .font(.headline)
                    .foregroundColor(paletaResumen.texto)

                Spacer()

                if hayDatos {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(paletaResumen.rielSelector)
                            .frame(width: 12, height: 12)

                        Text("Comprometido")
                            .font(.system(size: 14))
                            .foregroundColor(paletaResumen.textoSecundario)
                    }

                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(paletaResumen.turquesa)
                            .frame(width: 12, height: 12)

                        Text("Cobrado")
                            .font(.system(size: 14))
                            .foregroundColor(paletaResumen.textoSecundario)
                    }
                    .padding(.leading, 16)
                }
            }

            if hayDatos {
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(tramos) { tramo in
                        VStack(spacing: 14) {
                            HStack(alignment: .bottom, spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(paletaResumen.rielSelector)
                                    .frame(width: 18, height: altura(tramo.comprometido))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(paletaResumen.turquesa)
                                    .frame(width: 18, height: altura(tramo.cobrado))
                            }

                            Text(tramo.etiqueta)
                                .font(.system(size: 13))
                                .foregroundColor(paletaResumen.textoSecundario)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                Text("No hay datos de ingresos para este periodo.")
                    .font(.system(size: 15))
                    .foregroundColor(paletaResumen.textoSecundario)
                    .frame(maxWidth: .infinity, minHeight: alturaMaxima)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(paletaResumen.superficie)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func altura(_ valor: Double) -> Double {
        return valor / maximo * alturaMaxima
    }
}

#Preview("Con datos") {
    GraficaIngresos(titulo: "Ingresos por semana", tramos: [
        TramoIngreso(orden: 1, etiqueta: "Sem 36", comprometido: 430000, cobrado: 352000),
        TramoIngreso(orden: 2, etiqueta: "Sem 37", comprometido: 486000, cobrado: 398000),
        TramoIngreso(orden: 3, etiqueta: "Sem 38", comprometido: 524000, cobrado: 421000),
        TramoIngreso(orden: 4, etiqueta: "Sem 39", comprometido: 560000, cobrado: 468000),
        TramoIngreso(orden: 5, etiqueta: "Sem 40", comprometido: 402000, cobrado: 318000)
    ], alturaMaxima: 190)
        .padding()
        .background(paletaResumen.fondo)
}

#Preview("Sin datos") {
    GraficaIngresos(titulo: "Ingresos del día", tramos: [
        TramoIngreso(orden: 1, etiqueta: "24 Sep", comprometido: 0, cobrado: 0)
    ], alturaMaxima: 190)
        .padding()
        .background(paletaResumen.fondo)
}
