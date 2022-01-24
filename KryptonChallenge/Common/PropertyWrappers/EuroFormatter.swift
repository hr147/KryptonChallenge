import Foundation

@propertyWrapper
struct EuroFormatter {
    var wrappedValue: String?
}

extension EuroFormatter: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Double.self)

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2

        let number = NSNumber(value: rawValue)
        wrappedValue = formatter.string(from: number)
    }
}
