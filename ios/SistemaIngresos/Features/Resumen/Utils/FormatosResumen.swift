import Foundation

struct FormatosResumen {
    func moneda(_ monto: Double) -> String {
        return monto.formatted(.currency(code: "MXN").precision(.fractionLength(0)))
    }

    func entero(_ valor: Int) -> String {
        return valor.formatted(.number)
    }
}

let formatosResumen = FormatosResumen()
