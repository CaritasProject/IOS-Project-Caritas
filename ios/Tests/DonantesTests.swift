import Foundation

final class MockHTTP: URLProtocol {
    static var responder: (URLRequest) -> (Int, Data, Double) = { _ in (500, Data(), 0) }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let (status, data, delay) = Self.responder(request)
        guard let url = request.url, let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else { return }
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
    override func stopLoading() {}
}

@main struct DonantesTests {
    @MainActor static func main() async throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: "ios/Tests/Fixtures/donantes.json"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let donors = try decoder.decode([Donante].self, from: data)
        precondition(donors[0].nivelRiesgo == .amarillo)
        precondition(donors[0].estadoVisual == .amarillo, "El semáforo debe depender del nivel de riesgo, no del estatus")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let first = try encoder.encode(donors[0])
        let second = try encoder.encode(donors[1])
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockHTTP.self]
        let api = APIClient(baseURL: "https://example.test", sesion: URLSession(configuration: config), token: { "test-token" })
        MockHTTP.responder = { request in
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
            switch request.url?.path {
            case "/donantes": return (200, data, 0)
            case "/donantes/1": return (200, first, 0.15)
            case "/donantes/2": return (200, second, 0)
            default: return (404, Data(), 0)
            }
        }
        let service = DonantesService(api: api)
        await service.load()
        precondition(service.donors.count == 2 && service.selectedDonante?.id == 1)
        service.selectedCategory = .active
        precondition(service.filteredDonantes.count == 2, "Segmento no debe excluir donantes activos")
        service.selectedCategory = .highValue
        precondition(service.filteredDonantes.map(\.id) == [2])
        service.selectedCategory = .all
        service.searchText = " maria "
        precondition(service.filteredDonantes.map(\.id) == [1])
        service.searchText = ""
        let slow = Task { await service.select(donors[0]) }
        try await Task.sleep(nanoseconds: 20_000_000)
        await service.select(donors[1])
        await slow.value
        precondition(service.selectedDonante?.id == 2, "Una respuesta vieja reemplazó la selección")
        service.searchText = "nadie"
        service.conciliarSeleccion()
        precondition(service.selectedDonante == nil)
        MockHTTP.responder = { _ in (401, Data(), 0) }
        await service.recargar()
        precondition(service.error != nil && !service.cargando)
        MockHTTP.responder = { _ in (200, Data("[]".utf8), 0) }
        await service.recargar()
        precondition(service.donors.isEmpty && service.error == nil)
        MockHTTP.responder = { _ in (200, Data("{}".utf8), 0) }
        await service.recargar()
        precondition(service.error != nil)
        MockHTTP.responder = { request in
            precondition(request.url?.path == "/api/donors")
            return (200, Data("[]".utf8), 0)
        }
        let alternate = DonantesService(api: api, ruta: "api/donors")
        await alternate.load()
        precondition(alternate.error == nil)
        print("PASS: contrato JSON, listado/detalle, token, filtros, búsqueda, selección concurrente, lista vacía, errores, reintento y ruta configurable")
    }
}
