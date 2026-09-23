import Foundation
import Combine

@MainActor
final class DonantesService: ObservableObject {
    enum Category: String, CaseIterable, Identifiable {
        case all = "Todos", risk = "En riesgo", highValue = "Alto valor"
        case active = "Activos", inactive = "Inactivos"
        var id: Self { self }
    }

    @Published private(set) var donors: [Donante] = []
    @Published private(set) var selectedDonante: Donante?
    @Published var searchText = ""
    @Published var selectedCategory: Category = .all
    @Published private(set) var cargando = false
    @Published private(set) var cargandoDetalle = false
    @Published private(set) var error: String?
    private let ruta: String
    private let api: APIClient
    private var cargado = false
    private var seleccionVersion = UUID()

    init(api: APIClient = .compartido, ruta: String? = nil) {
        self.api = api
        self.ruta = ruta ?? ProcessInfo.processInfo.environment["API_DONANTES_PATH"] ?? "donantes"
    }

    var filteredDonantes: [Donante] {
        let busqueda = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return donors.filter { donor in
            let categoria = switch selectedCategory {
            case .all: true
            case .risk: donor.segmento == "en_riesgo"
            case .highValue: donor.segmento == "alto_valor"
            case .active: donor.estado == "activo"
            case .inactive: donor.estado == "inactivo"
            }
            return categoria && (busqueda.isEmpty || donor.nombre.localizedStandardContains(busqueda))
        }
    }

    func load() async {
        guard !cargado else { return }
        await recargar()
    }

    func recargar() async {
        guard !cargando else { return }
        cargando = true
        error = nil
        defer { cargando = false }
        do {
            let respuesta: [Donante] = try await api.get(ruta)
            donors = respuesta
            cargado = true
            let siguiente = filteredDonantes.first { $0.id == selectedDonante?.id } ?? filteredDonantes.first
            if let siguiente { await select(siguiente) }
            else { limpiarSeleccion() }
        } catch is CancellationError {
        } catch {
            if (error as? URLError)?.code != .cancelled { self.error = error.localizedDescription }
        }
    }

    private func limpiarSeleccion() {
        seleccionVersion = UUID()
        selectedDonante = nil
        cargandoDetalle = false
    }

    func conciliarSeleccion() {
        guard !filteredDonantes.contains(where: { $0.id == selectedDonante?.id }) else { return }
        limpiarSeleccion()
        // Capture the generation so an old filter task cannot replace a newer selection.
        let version = seleccionVersion
        if let primero = filteredDonantes.first {
            Task {
                guard version == seleccionVersion else { return }
                await select(primero)
            }
        }
    }

    func select(_ donor: Donante) async {
        let version = UUID()
        seleccionVersion = version
        selectedDonante = donor
        cargandoDetalle = true
        error = nil
        defer { if seleccionVersion == version { cargandoDetalle = false } }
        do {
            let respuesta: Donante = try await api.get("\(ruta)/\(donor.id)")
            guard seleccionVersion == version else { return }
            selectedDonante = respuesta
        } catch {
            guard seleccionVersion == version else { return }
            if (error as? URLError)?.code != .cancelled { self.error = error.localizedDescription }
        }
    }
}
