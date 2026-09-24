//
//  MetasView.swift
//  Features / Metas — Dueño: Persona 5.
//
//  Solo presenta. Los datos los trae MetasService desde /metas.
//  Los modelos viven en Features/Metas/Model/MetaAvance.swift.
//

import SwiftUI
import Charts

struct MetasView: View {

    @StateObject private var servicio: MetasService
    @State private var periodo: Periodo = .trimestre
    // Se guarda el ID de la meta, nunca su posición en el arreglo:
    // los ID_META de la base empiezan en 1 y no son índices.
    @State private var metaSeleccionadaID: Int?

    init(servicio: MetasService = MetasService()) {
        _servicio = StateObject(wrappedValue: servicio)
    }

    /// Si la meta elegida ya no está en el periodo actual, cae en la primera.
    private var metaSeleccionada: MetaAvance? {
        servicio.metas.first { $0.id == metaSeleccionadaID } ?? servicio.metas.first
    }

    var body: some View {
        VStack(spacing: 0) {
            encabezado
            Divider()
            HStack(spacing: 0) {
                listaMetas
                    .frame(width: 380)
                    .background(Palette.superficie)
                Divider()
                detalle
                    .background(Palette.fondo)
            }
        }
        .task { await servicio.cargar(periodo: periodo) }
        .onChange(of: periodo) { _, nuevo in
            Task { await servicio.cargar(periodo: nuevo) }
        }
    }

    // MARK: - Encabezado

    private var encabezado: some View {
        HStack {
            Text("Metas")
                .font(.title2)
                .bold()

            Spacer()

            Picker(selection: $periodo, label: Text("Periodo")) {
                ForEach(Periodo.allCases) { opcion in
                    Text(opcion.etiqueta).tag(opcion)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 450)

            Spacer()

            AvatarUsuario(tamano: 45)
        }
        .padding()
        .background(Palette.superficie)
    }

    // MARK: - Lista de metas

    private var listaMetas: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Metas del periodo")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()

                if servicio.cargando && servicio.metas.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }

                if let error = servicio.error {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(Palette.riesgoAlto)
                        .padding()
                }

                if !servicio.cargando && servicio.metas.isEmpty && servicio.error == nil {
                    Text("No hay metas registradas en este periodo.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding()
                }

                ForEach(servicio.metas) { meta in
                    Button {
                        metaSeleccionadaID = meta.id
                    } label: {
                        filaMeta(meta)
                    }
                    .buttonStyle(.plain)

                    Divider()
                }
            }
        }
    }

    private func filaMeta(_ meta: MetaAvance) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(meta.color)
                    .frame(width: 10, height: 10)
                Text(meta.nombre)
                    .font(.headline)
                Spacer()
                Text("\(meta.porcentaje)%")
                    .font(.headline)
                    .foregroundColor(Palette.turquesa)
            }

            ProgressView(value: min(meta.cobrado, meta.objetivo),
                         total: max(meta.objetivo, 1))
                .tint(Palette.turquesa)
                .scaleEffect(x: 1, y: 2)
                .padding(.vertical, 4)

            Text("\(dinero(meta.cobrado)) de \(dinero(meta.objetivo))")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(meta.id == metaSeleccionada?.id
                    ? Palette.turquesa.opacity(0.15)
                    : Palette.superficie)
        .contentShape(Rectangle())
    }

    // MARK: - Detalle

    @ViewBuilder
    private var detalle: some View {
        if let meta = metaSeleccionada {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(meta.lineaEstrategica) · Procuración de Fondos")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(meta.nombre)
                        .font(.largeTitle)
                        .bold()

                    avanceDelPeriodo(meta)
                    tarjetasDeMontos(meta)
                    avanceMensual(meta)

                    Text("\(meta.donantes.formatted()) donantes activos")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(25)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack {
                Spacer()
                Text("Selecciona una meta")
                    .foregroundColor(.gray)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func avanceDelPeriodo(_ meta: MetaAvance) -> some View {
        HStack(spacing: 30) {
            ZStack {
                Chart(datosPastel(meta)) { item in
                    SectorMark(
                        angle: .value("Valor", item.valor),
                        innerRadius: .ratio(0.7)
                    )
                    .foregroundStyle(by: .value("Categoría", item.categoria))
                }
                .chartForegroundStyleScale([
                    "Cobrado": Palette.turquesa,
                    "Faltante": Color.gray.opacity(0.3)
                ])
                .chartLegend(.hidden)

                Text("\(meta.porcentaje)%")
                    .font(.system(size: 36))
                    .bold()
                    .foregroundColor(Palette.turquesa)
            }
            .frame(width: 180, height: 180)

            VStack(alignment: .leading, spacing: 12) {
                Text("Avance del periodo")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("\(dinero(meta.cobrado)) de \(dinero(meta.objetivo))")
                    .font(.title2)
                    .bold()

                leyenda(color: Palette.turquesa, texto: "Cobrado")
                leyenda(color: Color.gray.opacity(0.3), texto: "Faltante")
            }

            Spacer()
        }
        .padding()
        .background(Palette.superficie)
        .cornerRadius(15)
    }

    private func leyenda(color: Color, texto: String) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(texto)
        }
    }

    private func tarjetasDeMontos(_ meta: MetaAvance) -> some View {
        HStack(spacing: 15) {
            tarjeta(titulo: "Comprometido", monto: meta.comprometido)
            tarjeta(titulo: "Cobrado", monto: meta.cobrado, color: Palette.turquesa)
            tarjeta(titulo: "Faltante", monto: meta.faltante)
        }
    }

    private func tarjeta(titulo: String, monto: Double, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titulo)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(dinero(monto))
                .font(.title2)
                .bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Palette.superficie)
        .cornerRadius(15)
    }

    private func avanceMensual(_ meta: MetaAvance) -> some View {
        VStack(alignment: .leading) {
            Text("Avance mensual")
                .font(.headline)

            if meta.mensual.isEmpty {
                Text("Sin cobros registrados en el periodo.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(height: 220)
            } else {
                Chart(meta.mensual) { item in
                    BarMark(
                        x: .value("Mes", item.nombre),
                        y: .value("Monto", item.monto)
                    )
                    .foregroundStyle(Palette.turquesa)
                }
                .frame(height: 220)
            }
        }
        .padding()
        .background(Palette.superficie)
        .cornerRadius(15)
    }

    // MARK: - Utilidades

    private func datosPastel(_ meta: MetaAvance) -> [Rebanada] {
        [
            Rebanada(id: 1, categoria: "Cobrado", valor: meta.cobrado),
            Rebanada(id: 2, categoria: "Faltante", valor: meta.faltante)
        ]
    }

    private func dinero(_ cantidad: Double) -> String {
        cantidad.formatted(
            .currency(code: "MXN")
                .precision(.fractionLength(0))
                .locale(Locale(identifier: "es_MX"))
        )
    }
}

#Preview(traits: .landscapeLeft) {
    MetasView(servicio: .previsualizacion)
        .environmentObject(SesionService())
}
