import XCTest
import RxSwift

@testable import KryptonChallenge

class StockViewModelTests: XCTestCase {
    var mockUseCase: StockUseCaseMock!
    var sut: StockViewModel!
    var disposeBag = DisposeBag()
    
    override func setUp() {
        mockUseCase = .init()
        sut = .init(useCase: mockUseCase,stocks: mockStocks)
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        mockUseCase = nil
        sut = nil
    }
    
    func testViewDidLoad_shouldHaveValidValues() {
        XCTAssertEqual(sut.screenTitle, NSLocalizedString("screen_title", comment: ""))
        XCTAssertEqual(sut.subscribeButtonTitle, NSLocalizedString("subscribe_button_title", comment: ""))
        XCTAssertEqual(sut.unsubscribeButtonTitle, NSLocalizedString("unsubscribe_button_title", comment: ""))
    }
    
    func testStocksOutput_whenServerReturnValues_shouldHaveReturnStocks() {
        // Given
        let viewDidLoadSubject = PublishSubject<Void>()
        var didCallStocks = false
        let input = StockViewModel.Input(
            trigger: viewDidLoadSubject.asDriverOnErrorJustComplete(),
            changeSubscription: .empty()
        )
        
        let output = sut.transform(input: input)
        
        output.stocks.drive { rows in
            didCallStocks = true
            XCTAssertEqual(rows.count, 3)
        }
        .disposed(by: disposeBag)

        // When
        viewDidLoadSubject.onNext(())
        
        // Then
        XCTAssertTrue(didCallStocks)
    }
    
    func testChangeSubscriptionOutput_whenTypeIsSubscribe_shouldHaveCalledToBackend() {
        // Given
        let changeSubscriptionSubject = PublishSubject<SubscriptionAction>()
        let index = 1
        
        let input = StockViewModel.Input(
            trigger: .empty(),
            changeSubscription: changeSubscriptionSubject.asDriverOnErrorJustComplete()
        )
        
        let output = sut.transform(input: input)
        output.stocksDidUpdate.drive().disposed(by: disposeBag)
        
        // When
        changeSubscriptionSubject.onNext(.subscribed(atIndex: index))
        
        // Then
        XCTAssertEqual(mockUseCase.stockIdForSubscribe, mockStocks[index].id)
    }
    
    func testChangeSubscriptionOutput_whenTypeIsUnsubscribe_shouldHaveCalledToBackend() {
        // Given
        let changeSubscriptionSubject = PublishSubject<SubscriptionAction>()
        let index = 2
        
        let input = StockViewModel.Input(
            trigger: .empty(),
            changeSubscription: changeSubscriptionSubject.asDriverOnErrorJustComplete()
        )
        
        let output = sut.transform(input: input)
        output.stocksDidUpdate.drive().disposed(by: disposeBag)
        
        // When
        changeSubscriptionSubject.onNext(.unsubscribe(atIndex: index))
        
        // Then
        XCTAssertEqual(mockUseCase.stockIdForUnsubscribe, mockStocks[index].id)
    }
    
    func testStocksDidUpdateOutput_whenServerReturnNewStock_shouldHaveUpdatedRow() {
        // Given
        let index = 0
        let expectedPrice = "12345"
        var expectedStock = mockStocks[index]
        expectedStock.price = expectedPrice
        var currentPrice: String?
        var currentRows: [StockRowViewModel] = []
        
        let input = StockViewModel.Input(
            trigger: .just(()),
            changeSubscription: .empty()
        )
        
        let output = sut.transform(input: input)
        
        output.stocks.drive { rows in
            currentRows = rows
        }.disposed(by: disposeBag)
        
        output.stocksDidUpdate.drive().disposed(by: disposeBag)
        
        currentRows[index].price.subscribe { event in
            guard case let .next(price) = event else {
                return
            }

            currentPrice = price
        }
        .disposed(by: disposeBag)
        
        // When
        mockUseCase.fetchStocksSubject.onNext(expectedStock)
        
        // Then
        XCTAssertEqual(expectedPrice, currentPrice)
    }
}
