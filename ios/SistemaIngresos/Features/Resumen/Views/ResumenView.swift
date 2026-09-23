//
//  ResumenView.swift
//  Features / Resumen — Dueño: Persona 2.
//

import SwiftUI

struct ResumenView: View {
    @State private var periodoSeleccionado: Int = 2

    private let semanas = [
        SemanaIngreso(id: 31, etiqueta: "Sem 31", comprometido: 430000, cobrado: 352000),
        SemanaIngreso(id: 32, etiqueta: "Sem 32", comprometido: 486000, cobrado: 398000),
        SemanaIngreso(id: 33, etiqueta: "Sem 33", comprometido: 524000, cobrado: 421000),
        SemanaIngreso(id: 34, etiqueta: "Sem 34", comprometido: 560000, cobrado: 468000),
        SemanaIngreso(id: 35, etiqueta: "Sem 35", comprometido: 402000, cobrado: 318000)
    ]

    var body: some View {
        HStack(spacing: 0) {
            BarraLateral()

            Rectangle()
                .fill(paletaResumen.separador)
                .frame(width: 1)

            VStack(spacing: 0) {
                BarraSuperior(titulo: "Resumen",
                              iniciales: "MG",
                              periodoSeleccionado: $periodoSeleccionado)

                ScrollView {
                    VStack(spacing: 20) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Resumen")
                                .font(.system(size: 38))
                                .fontWeight(.bold)
                                .foregroundColor(paletaResumen.texto)

                            Spacer()

                            Text("Agosto 2026")
                                .font(.system(size: 17))
                                .foregroundColor(paletaResumen.textoSecundario)
                        }

                        HStack(alignment: .top, spacing: 20) {
                            TarjetaIngresos(comprometido: "$2,340,000",
                                            detalleComprometido: "1,842 compromisos",
                                            cobrado: "$1,812,400",
                                            detalleCobrado: "1,394 cobros aplicados",
                                            porcentajeCobranza: 77.5)
                                .frame(maxHeight: .infinity)

                            TarjetaMetas(porcentaje: 76,
                                         detalle: "$1,812,400 de $2,400,000")
                                .frame(width: 340)
                                .frame(maxHeight: .infinity)
                        }

                        HStack(alignment: .top, spacing: 20) {
                            TarjetaIndicador(titulo: "Donantes en riesgo",
                                             numero: "148",
                                             colorPrimerPunto: paletaResumen.riesgoAlto,
                                             primerDetalle: "42 con dos cobros vencidos",
                                             colorSegundoPunto: paletaResumen.riesgoMedio,
                                             segundoDetalle: "106 con un cobro vencido")
                                .frame(maxHeight: .infinity)

                            TarjetaIndicador(titulo: "Top 10 %",
                                             numero: "312",
                                             colorPrimerPunto: paletaResumen.riesgoBajo,
                                             primerDetalle: "289 al corriente",
                                             colorSegundoPunto: nil,
                                             segundoDetalle: "Aportan el 61 % de lo cobrado")
                                .frame(maxHeight: .infinity)

                            TarjetaTelemarketing(llamadas: "4,820",
                                                 compromisos: "612",
                                                 conversion: "12.7 %")
                                .frame(maxHeight: .infinity)
                        }

                        GraficaIngresosSemana(semanas: semanas, alturaMaxima: 190)
                    }
                    .padding(24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(paletaResumen.fondo)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(paletaResumen.fondo)
        .ignoresSafeArea()
    }
}

#Preview {
    ResumenView()
}
