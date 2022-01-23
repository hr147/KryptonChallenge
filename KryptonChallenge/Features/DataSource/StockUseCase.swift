//
//  StockUseCase.swift
//  KryptonChallenge
//
//  Created on 23.01.22.
//

import Foundation
import RxSwift

protocol StockUseCase {
    func fetchStocks() -> Observable<Stock>
    func subscribe(_ stock: Stock) -> Completable
    func unsubscribe(_ stock: Stock) -> Completable
}

class SocketStockUseCase: StockUseCase {
    enum StockUseCaseImpError: Error {
        case invalidData
    }
    
    let handler: SocketHandling
    
    init(handler: SocketHandling) {
        self.handler = handler
    }
    
    func fetchStocks() -> Observable<Stock> {
        return handler.rawData.map { raw in
            guard let data = raw.data(using: .utf8) else {
                throw StockUseCaseImpError.invalidData
            }
            
            return try JSONDecoder().decode(Stock.self, from: data)
        }
    }
    
    func subscribe(_ stock: Stock) -> Completable {
        handler.write(jsonData: ["subscribe": stock.id])
    }
    
    func unsubscribe(_ stock: Stock) -> Completable {
        handler.write(jsonData: ["unsubscribe": stock.id])
    }
}
