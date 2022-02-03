import Foundation

struct Stock {
    let id: String
    var name: String = ""
    let openMarketPrice: Double
    
    //@EuroFormatter
    let price: Double
    
    init(id: String, name: String, price: Double = 0.0, openMarketPrice: Double = 0.0) {
        self.id = id
        self.name = name
        self.price = price
        self.openMarketPrice = openMarketPrice
    }
}

extension Stock: Decodable {
    private enum CodingKeys : String, CodingKey {
        case id = "isin" , price, openMarketPrice = "open"
    }
}
