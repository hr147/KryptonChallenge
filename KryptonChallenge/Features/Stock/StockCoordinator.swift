//
//  StockCoordinator.swift
//  KryptonChallenge
//
//  Created on 23.01.22.
//

import UIKit

final class StockCoordinator: BaseCoordinator<UINavigationController> {
    override func start() {
        let factory = StockViewControllerFactory()
        guard let stockViewController = factory.makeStockViewController() else {
            return assertionFailure()
        }
        
        rootViewController.pushViewController(stockViewController, animated: true)
    }
}
