import SwiftUI

struct TarjetaIndicador: View {
    let titulo: String
    let numero: String
    let colorPrimerPunto: Color
    let primerDetalle: String
    let colorSegundoPunto: Color?
    let segundoDetalle: String

    var body: some View {
        TarjetaPanel(titulo: titulo, mostrarFlecha: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text(numero)
                    .font(.system(size: 44))
                    .fontWeight(.bold)
                    .foregroundColor(paletaResumen.texto)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(colorPrimerPunto)
                            .frame(width: 9, height: 9)

                        Text(primerDetalle)
                            .font(.system(size: 15))
                            .foregroundColor(paletaResumen.texto)
                    }

                    HStack(spacing: 10) {
                        if let color = colorSegundoPunto {
                            Circle()
                                .fill(color)
                                .frame(width: 9, height: 9)

                            Text(segundoDetalle)
                                .font(.system(size: 15))
                                .foregroundColor(paletaResumen.texto)
                        } else {
                            Text(segundoDetalle)
                                .font(.system(size: 15))
                                .foregroundColor(paletaResumen.textoSecundario)
                        }
                    }
                }

                Spacer()
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        TarjetaIndicador(titulo: "Donantes en riesgo",
                         numero: "148",
                         colorPrimerPunto: paletaResumen.riesgoAlto,
                         primerDetalle: "42 con dos cobros vencidos",
                         colorSegundoPunto: paletaResumen.riesgoMedio,
                         segundoDetalle: "106 con un cobro vencido")

        TarjetaIndicador(titulo: "Top 10 %",
                         numero: "312",
                         colorPrimerPunto: paletaResumen.riesgoBajo,
                         primerDetalle: "289 al corriente",
                         colorSegundoPunto: nil,
                         segundoDetalle: "Aportan el 61 % de lo cobrado")
    }
    .padding()
    .background(paletaResumen.fondo)
}
