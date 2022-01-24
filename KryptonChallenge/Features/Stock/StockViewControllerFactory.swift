//
//  StockViewControllerFactory.swift
//  KryptonChallenge
//
//  Created on 23.01.22.
//

import UIKit

final class StockViewControllerFactory {
    func makeStockViewController() -> StockViewController? {
        let storyboard = UIStoryboard(name: .stock )
        let controller = storyboard.instantiateInitialViewController { coder in
            StockViewController(coder: coder, viewModel: StockViewModel(useCase: SocketStockUseCase(handler: handler)))
        }
        
        return controller
    }
}
