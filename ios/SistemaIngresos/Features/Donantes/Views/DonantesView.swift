import SwiftUI

struct DonantesView: View {
    enum DetailSection: String, CaseIterable, Identifiable {
        case payments = "Historial de pagos"
        case calls = "Bitácora de llamadas"

        var id: Self { self }
    }

    @StateObject private var viewModel = DonantesService()
    @State private var selectedSection: DetailSection = .payments

    var body: some View {
        VStack(spacing: 0) {
            BarraSuperior(titulo: "Donantes",
                          mostrarPeriodo: false,
                          periodoSeleccionado: .constant(0))

            Divider()

            contenido
        }
    }

    private var contenido: some View {
        HStack(spacing: 0) {
            donorPanel
                .frame(width: 380)
            Divider()
            detailPanel
        }
        .background(Color.white)
        .safeAreaInset(edge: .top) {
            VStack(spacing: 6) {
                if viewModel.cargando { ProgressView("Cargando donantes…") }
                if let error = viewModel.error {
                    HStack {
                        Text(error).font(.callout)
                        Button("Reintentar") { Task { await viewModel.recargar() } }
                    }.padding(8)
                }
            }
        }
        .onChange(of: viewModel.searchText) { _, _ in viewModel.conciliarSeleccion() }
        .onChange(of: viewModel.selectedCategory) { _, _ in viewModel.conciliarSeleccion() }
        .task {
            await viewModel.load()
        }
    }

    private var donorPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Buscar donante", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(Color(.systemGray6), in: Capsule())
            .padding(.horizontal, 16)
            .padding(.top, 14)

            filterButtons
                .padding(.horizontal, 16)
                .padding(.top, 12)

            Text("\(viewModel.filteredDonantes.count) donantes")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            if viewModel.filteredDonantes.isEmpty && !viewModel.cargando {
                ContentUnavailableView("Sin resultados", systemImage: "person.2", description: Text("Prueba otra búsqueda o filtro."))
            }
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredDonantes) { donor in
                        Button {
                            Task { await viewModel.select(donor) }
                        } label: {
                            DonanteRow(donor: donor, isSelected: viewModel.selectedDonante?.id == donor.id)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
        .background(.white)
    }

    private var filterButtons: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                filterButton(.all)
                filterButton(.risk)
                filterButton(.highValue)
            }
            HStack(spacing: 6) {
                filterButton(.active)
                filterButton(.inactive)
            }
        }
    }

    private func filterButton(_ category: DonantesService.Category) -> some View {
        Button(category.rawValue) {
            viewModel.selectedCategory = category
        }
        .font(.system(size: 14, weight: category == viewModel.selectedCategory ? .semibold : .regular))
        .foregroundStyle(category == viewModel.selectedCategory ? .white : .primary)
        .padding(.horizontal, 14)
        .frame(height: 32)
        .background(category == viewModel.selectedCategory ? Palette.turquesa : Color(.systemGray6), in: Capsule())
        .buttonStyle(.plain)
    }

    private var detailPanel: some View {
        Group {
            if let donor = viewModel.selectedDonante {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if viewModel.cargandoDetalle { ProgressView("Cargando detalle…") }
                        Text(donor.nombre)
                            .font(.system(size: 32, weight: .bold))

                        statusBadge(for: donor)

                        informationCard(for: donor)

                        Picker("Detalle", selection: $selectedSection) {
                            ForEach(DetailSection.allCases) { section in
                                Text(section.rawValue).tag(section)
                            }
                        }
                        .pickerStyle(.segmented)

                        if selectedSection == .payments {
                            paymentHistory(donor.pagos)
                        } else {
                            callHistory(donor.llamadas)
                        }
                    }
                    .padding(24)
                }
            } else {
                ContentUnavailableView("Selecciona un donante", systemImage: "person.crop.circle")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.fondo)
    }

    private func statusBadge(for donor: Donante) -> some View {
        HStack(spacing: 9) {
            Circle()
                .fill(donor.estadoVisual.color)
                .frame(width: 10, height: 10)
            Text(donor.estadoVisual.title)
                .font(.system(size: 14, weight: .semibold))
            Text(donor.detalleEstado)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .frame(height: 38)
        .background(.white, in: Capsule())
    }

    private func informationCard(for donor: Donante) -> some View {
        HStack(alignment: .top, spacing: 20) {
            informationItem("Primera donación", donor.primeraDonacion.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "es_MX"))))
            informationItem("Frecuencia", donor.frecuencia)
            informationItem("Monto promedio", donor.montoPromedio.currency)
            informationItem("Acumulado 12 meses", donor.acumulado12Meses.currency, highlighted: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
    }

    private func informationItem(_ title: String, _ value: String, highlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(highlighted ? Palette.turquesa : .primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func paymentHistory(_ payments: [PagoDonante]) -> some View {
        VStack(spacing: 0) {
            if payments.isEmpty { Text("Sin pagos registrados").foregroundStyle(.secondary).padding() }
            ForEach(payments) { payment in
                HStack {
                    Text(payment.date.donorDate)
                    Spacer()
                    Text(payment.amount.currency)
                        .fontWeight(.semibold)
                        .frame(width: 120, alignment: .trailing)
                    HStack(spacing: 8) {
                        Circle()
                            .fill(payment.status == .paid ? Palette.riesgoBajo : payment.status == .pending ? Palette.riesgoMedio : Palette.riesgoAlto)
                            .frame(width: 9, height: 9)
                        Text(payment.status.title)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 120, alignment: .leading)
                }
                .padding(.horizontal, 18)
                .frame(height: 52)
                if payment.id != payments.last?.id {
                    Divider()
                }
            }
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
    }

    private func callHistory(_ calls: [LlamadaDonante]) -> some View {
        VStack(spacing: 0) {
            if calls.isEmpty { Text("Sin llamadas registradas").foregroundStyle(.secondary).padding() }
            ForEach(calls) { call in
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(call.date.donorDate)
                            .fontWeight(.semibold)
                        Text(call.result)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(call.notes)
                        .font(.subheadline)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 360, alignment: .trailing)
                }
                .padding(18)
                if call.id != calls.last?.id {
                    Divider()
                }
            }
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    DonantesView()
        .frame(width: 1180, height: 760)
        .environmentObject(SesionService())
}
