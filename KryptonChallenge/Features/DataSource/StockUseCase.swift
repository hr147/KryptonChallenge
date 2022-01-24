//
//  StockUseCase.swift
//  KryptonChallenge
//
//  Created on 23.01.22.
//

import Foundation
import RxSwift

/// `StockUseCase` use for retrieving stocks and request to provider for subscribe/unsubscribe stock.
protocol StockUseCase {
    /// Fetch stocks which are only subscribed by the user.
    /// - Returns: `Observable` of stock which will emit stream of updated stock.
    func fetchStocks() -> Observable<Stock>
    
    /// Subscribe to get latest updates of specify stock.
    /// - Returns: `Completable` which triggered when execution is completed.
    func subscribe(withStockId stockId: String) -> Completable
    
    /// Unsubscribe to stop getting latest updates of specify stock.
    /// - Returns: `Completable` which triggered when execution is completed.
    func unsubscribe(withStockId stockId: String) -> Completable
}

class SocketStockUseCase: StockUseCase {
    enum StockUseCaseImpError: LocalizedError {
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .invalidData:
                return NSLocalizedString("invalid_data_error", comment: "")
            }
        }
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
    
    func subscribe(withStockId stockId: String) -> Completable {
        handler.write(jsonData: ["subscribe": stockId])
    }
    
    func unsubscribe(withStockId stockId: String) -> Completable {
        handler.write(jsonData: ["unsubscribe": stockId])
    }
}
