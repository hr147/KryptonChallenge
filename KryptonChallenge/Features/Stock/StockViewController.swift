import UIKit
import RxRelay
import RxSwift

final class StockViewController: UITableViewController {
    // MARK: Private Properties
    private let disposeBag = DisposeBag()
    private let subscriptionAction = PublishSubject<SubscriptionAction>()
    private lazy var dataSource = makeDataSource()
    private let viewModel: StockViewModel
    
    // MARK: Life Cycle
    
    init?(coder: NSCoder, viewModel: StockViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
        bindViewModel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("You must create this view controller with a user.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let subscribeAction = UIContextualAction(
            style: .normal,
            title: viewModel.subscribeButtonTitle
        ) { [weak self] (action, view, completionHandler) in
            self?.subscriptionAction.onNext(.subscribed(atIndex: indexPath.row))
            completionHandler(true)
        }
        subscribeAction.backgroundColor = .systemGreen
        
        let unsubscribeAction = UIContextualAction(
            style: .destructive,
            title: viewModel.unsubscribeButtonTitle
        ) { [weak self] (action, view, completionHandler) in
            self?.subscriptionAction.onNext(.unsubscribe(atIndex: indexPath.row))
            completionHandler(true)
        }
        unsubscribeAction.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [subscribeAction, unsubscribeAction])
        
        return configuration
    }
    
    // MARK: Private Methods
    
    private func configureUI() {
        tableView.dataSource = dataSource
        title = viewModel.screenTitle
    }
    
    private func bindViewModel() {
        let viewDidLoad = rx.sentMessage(#selector(self.viewDidLoad))
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let input = StockViewModel.Input(
            trigger: viewDidLoad,
            changeSubscription: subscriptionAction.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input: input)
        
        [output.stocks.drive(onNext: {[weak self] rows in
            self?.update(with: rows)
        }),
         output.showAlert.drive(onNext: {[weak self] message in
            self?.presentAlert(message)
        }),
         output.stocksDidUpdate.drive()]
            .forEach({ $0.disposed(by: disposeBag) })
    }
}

fileprivate extension StockViewController {
    enum Section: CaseIterable {
        case stocks
    }
    
    private func makeDataSource() -> UITableViewDiffableDataSource<Section, StockRowViewModel> {
        return UITableViewDiffableDataSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, stock in
                let cell: StockTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(with: stock)
                return cell
            })
    }
    
    private func update(with stocks: [StockRowViewModel]) {
        DispatchQueue.main.async {
            var snapshot = NSDiffableDataSourceSnapshot<Section, StockRowViewModel>()
            snapshot.appendSections(Section.allCases)
            snapshot.appendItems(stocks, toSection: .stocks)
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
}
