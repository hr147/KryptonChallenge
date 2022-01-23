//
//  StockViewControllerFactory.swift
//  KryptonChallenge
//
//  Created on 23.01.22.
//

import UIKit

final class StockViewControllerFactory {
    func makeStockViewController() -> StocksViewController {
        let storyboard = UIStoryboard(name: .stock )
        return storyboard.initialViewController()
    }
}
