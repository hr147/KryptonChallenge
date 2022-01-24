import Foundation

struct Stock {
    let id: String
    var name: String = ""
    
    @EuroFormatter
    var price: String?
    
    init(id: String, name: String, price: String? = "--") {
        self.id = id
        self.name = name
        self.price = price
    }
}

extension Stock: Decodable {
    private enum CodingKeys : String, CodingKey {
        case id = "isin" , price
    }
}
