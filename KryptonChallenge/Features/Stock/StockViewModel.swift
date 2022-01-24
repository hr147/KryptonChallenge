import RxSwift
import RxCocoa
import Foundation

/// Use to identify which action is being sent by the user from UI.
enum SubscriptionAction {
    case subscribed(atIndex: Int)
    case unsubscribe(atIndex: Int)
    
    var index: Int {
        switch self {
        case .subscribed(let atIndex):
            return atIndex
        case .unsubscribe(let atIndex):
            return atIndex
        }
    }
    
    func isSubscribed() -> Bool {
        switch self {
        case .subscribed:
            return true
        case .unsubscribe:
            return false
        }
    }
}

final class StockViewModel {
    struct Input {
        let trigger: Driver<Void>
        let changeSubscription: Driver<SubscriptionAction>
    }
    
    struct Output {
        let stocks: Driver<[StockRowViewModel]>
        let stocksDidUpdate: Driver<Void>
        let showAlert: Driver<String>
    }
    
    let screenTitle = NSLocalizedString("screen_title", comment: "")
    let subscribeButtonTitle = NSLocalizedString("subscribe_button_title", comment: "")
    let unsubscribeButtonTitle = NSLocalizedString("unsubscribe_button_title", comment: "")
    
    private let useCase: StockUseCase
    private var rowViewModels: [StockRowViewModel]
    
    init(useCase: StockUseCase, stocks: [Stock] = defaultStocks) {
        self.useCase = useCase
        self.rowViewModels = stocks.map(StockRowViewModel.init(stock:))
    }
    
    func transform(input: Input) -> Output {
        let errorTracker = ErrorTracker()
        
        let stocks = input.trigger.map { self.rowViewModels }
        
        let changedStocks = input.trigger.asObservable()
            .flatMap {
                self.useCase.fetchStocks()
                    .trackError(errorTracker)
                    .do { stock in
                        self.rowViewModels.first { $0.id == stock.id }?.price.accept(stock.price)
                    }
            }
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let changeSubscription = input.changeSubscription
            .asObservable()
            .filter { $0.index < self.rowViewModels.count }
            .map { ($0, self.rowViewModels[$0.index].id) }
        
        let subscribed = changeSubscription
            .filter { $0.0.isSubscribed() }
            .flatMap {
                self.useCase.subscribe(withStockId: $0.1)
                    .trackError(errorTracker)
            }
        
        let unsubscribed = changeSubscription
            .filter { $0.0.isSubscribed() == false }
            .flatMap {
                self.useCase.unsubscribe(withStockId: $0.1)
                    .trackError(errorTracker)
            }
    
        let subscriptionCompleted = Observable.merge(subscribed, unsubscribed)
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        return Output(
            stocks: stocks,
            stocksDidUpdate: .merge(changedStocks, subscriptionCompleted),
            showAlert: errorTracker.map { $0.localizedDescription }
        )
    }
}
