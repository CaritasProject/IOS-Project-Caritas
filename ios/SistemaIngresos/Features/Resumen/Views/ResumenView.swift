//
//  ResumenView.swift
//  Features / Resumen — Dueño: Persona 2.
//

import SwiftUI

struct ResumenView: View {
    @State private var periodoSeleccionado: Int = 2
    @State private var kpis: ResumenKPIs?
    @State private var cargando = false
    @State private var mensajeError = ""
    @State private var mostrarError = false

    private let servicio = ResumenService()
    private let clavesPeriodo = ["dia", "semana", "mes", "trimestre", "ano"]

    var body: some View {
        VStack(spacing: 0) {
            BarraSuperior(titulo: "Resumen",
                          mostrarPeriodo: true,
                          periodoSeleccionado: $periodoSeleccionado)

            ScrollView {
                VStack(spacing: 20) {
                    encabezado
                    contenido
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(paletaResumen.fondo)
        .task {
            await cargar()
        }
        .onChange(of: periodoSeleccionado) { oldValue, newValue in
            Task {
                await cargar()
            }
        }
        .alert(mensajeError, isPresented: $mostrarError) {
            Button("OK") {}
        }
    }

    private var encabezado: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Resumen")
                .font(.system(size: 38))
                .fontWeight(.bold)
                .foregroundColor(paletaResumen.texto)

            Spacer()

            Text(kpis?.periodo.etiqueta ?? "")
                .font(.system(size: 17))
                .foregroundColor(paletaResumen.textoSecundario)
        }
    }

    @ViewBuilder
    private var contenido: some View {
        if let datos = kpis {
            HStack(alignment: .top, spacing: 20) {
                TarjetaIngresos(ingresos: datos.ingresos)
                    .frame(maxHeight: .infinity)

                TarjetaMetas(meta: datos.meta)
                    .frame(width: 340)
                    .frame(maxHeight: .infinity)
            }

            HStack(alignment: .top, spacing: 20) {
                TarjetaIndicador(titulo: "Donantes en riesgo",
                                 numero: formatosResumen.entero(datos.donantesEnRiesgo.total),
                                 colorPrimerPunto: paletaResumen.riesgoAlto,
                                 primerDetalle: "\(datos.donantesEnRiesgo.criticos) sin donar hace más de un año",
                                 colorSegundoPunto: paletaResumen.riesgoMedio,
                                 segundoDetalle: "\(datos.donantesEnRiesgo.moderados) con 1 a 12 meses sin donar")
                    .frame(maxHeight: .infinity)

                TarjetaIndicador(titulo: "Top 10 %",
                                 numero: formatosResumen.entero(datos.topDiez.total),
                                 colorPrimerPunto: paletaResumen.riesgoBajo,
                                 primerDetalle: "\(datos.topDiez.alCorriente) al corriente",
                                 colorSegundoPunto: nil,
                                 segundoDetalle: "Aportan el \(datos.topDiez.porcentajeDeLoCobrado.formatted(.number.precision(.fractionLength(0)))) % de lo cobrado")
                    .frame(maxHeight: .infinity)

                TarjetaTelemarketing(datos: datos.telemarketing)
                    .frame(maxHeight: .infinity)
            }

            GraficaIngresosSemana(semanas: datos.ingresosPorSemana, alturaMaxima: 190)
        } else if cargando {
            ProgressView()
                .padding(.top, 80)
        } else {
            Text("No hay información para este periodo.")
                .font(.system(size: 17))
                .foregroundColor(paletaResumen.textoSecundario)
                .padding(.top, 80)
        }
    }

    private func cargar() async {
        cargando = true
        do {
            kpis = try await servicio.obtenerKPIs(periodo: clavesPeriodo[periodoSeleccionado])
        } catch {
            kpis = nil
            mensajeError = error.localizedDescription
            mostrarError.toggle()
        }
        cargando = false
    }
}

#Preview {
    ResumenView()
        .environmentObject(SesionService())
}
