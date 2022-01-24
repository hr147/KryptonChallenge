//
//  StockUseCaseMock.swift
//  KryptonChallengeTests
//
//  Created on 24.01.22.
//

import Foundation
import RxSwift
@testable import KryptonChallenge

final class StockUseCaseMock: StockUseCase {
    let fetchStocksSubject = PublishSubject<Stock>()
    
    func fetchStocks() -> Observable<Stock> {
        fetchStocksSubject.asObservable()
    }
    
    private(set) var stockIdForSubscribe: String?
    let subscribeSubject = PublishSubject<Never>()
    
    func subscribe(withStockId stockId: String) -> Completable {
        stockIdForSubscribe = stockId
        return subscribeSubject.asCompletable()
    }
    
    private(set) var stockIdForUnsubscribe: String?
    let unsubscribeSubject = PublishSubject<Never>()
    
    func unsubscribe(withStockId stockId: String) -> Completable {
        stockIdForUnsubscribe = stockId
        return unsubscribeSubject.asCompletable()
    }
    

}
