//
//  StockRowViewModel.swift
//  KryptonChallenge
//
//  Created on 23.01.22.
//

import Foundation
import RxRelay

struct StockRowViewModel: Identifiable {
    let id: String
    let name: String
    let price: BehaviorRelay<String?>
    
    init(id: String, name: String, price: String) {
        self.id = id
        self.name = name
        self.price = .init(value: price)
    }
}

extension StockRowViewModel {
    init(stock: Stock) {
        self.id = stock.id
        self.name = stock.name
        self.price = .init(value: stock.price)
    }
}

extension StockRowViewModel: Hashable {
    static func == (lhs: StockRowViewModel, rhs: StockRowViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(price.value)
    }
}
