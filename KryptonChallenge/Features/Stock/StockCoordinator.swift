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
        let productViewController = factory.makeStockViewController()
        rootViewController.pushViewController(productViewController, animated: true)
    }
}
