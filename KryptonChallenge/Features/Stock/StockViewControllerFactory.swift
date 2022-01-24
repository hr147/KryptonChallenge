import UIKit

final class StockViewControllerFactory {
    func makeStockViewController() -> StockViewController? {
        let storyboard = UIStoryboard(name: .stock )
        let useCase: StockUseCase = DIContainer.resolve()
        let controller = storyboard.instantiateInitialViewController { coder in
            StockViewController(coder: coder, viewModel: StockViewModel(useCase: useCase))
        }
        
        return controller
    }
}
