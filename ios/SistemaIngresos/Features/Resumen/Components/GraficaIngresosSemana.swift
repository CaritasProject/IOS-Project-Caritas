import SwiftUI

struct GraficaIngresosSemana: View {
    let semanas: [SemanaIngreso]
    let alturaMaxima: Double

    private var maximo: Double {
        var mayor = 1.0
        for semana in semanas {
            if semana.comprometido > mayor { mayor = semana.comprometido }
            if semana.cobrado > mayor { mayor = semana.cobrado }
        }
        return mayor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Ingresos por semana")
                    .font(.headline)
                    .foregroundColor(paletaResumen.texto)

                Spacer()

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

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(semanas) { semana in
                    VStack(spacing: 14) {
                        HStack(alignment: .bottom, spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(paletaResumen.rielSelector)
                                .frame(width: 18, height: altura(semana.comprometido))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(paletaResumen.turquesa)
                                .frame(width: 18, height: altura(semana.cobrado))
                        }

                        Text(semana.etiqueta)
                            .font(.system(size: 13))
                            .foregroundColor(paletaResumen.textoSecundario)
                    }
                    .frame(maxWidth: .infinity)
                }
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

#Preview {
    GraficaIngresosSemana(semanas: [
        SemanaIngreso(id: 31, etiqueta: "Sem 31", comprometido: 430000, cobrado: 352000),
        SemanaIngreso(id: 32, etiqueta: "Sem 32", comprometido: 486000, cobrado: 398000),
        SemanaIngreso(id: 33, etiqueta: "Sem 33", comprometido: 524000, cobrado: 421000),
        SemanaIngreso(id: 34, etiqueta: "Sem 34", comprometido: 560000, cobrado: 468000),
        SemanaIngreso(id: 35, etiqueta: "Sem 35", comprometido: 402000, cobrado: 318000)
    ], alturaMaxima: 190)
        .padding()
        .background(paletaResumen.fondo)
}
