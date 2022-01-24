//
//  ViewController.swift
//  KryptonChallenge
//
//  Created on 22.01.22.
//

import UIKit
import RxRelay
import RxSwift

let stocks: [Stock] = [
    .init(id: "US0378331005", name: "Apple"),
    .init(id: "US88160R1014", name: "Tesla Motors"),
    .init(id: "DE000BASF111", name: "BASF"),
    .init(id: "US0231351067", name: "Amazon"),
    .init(id: "US30303M1027", name: "Facebook"),
    .init(id: "US5949181045", name: "Microsoft"),
    .init(id: "US67066G1040", name: "Nvidia"),
    .init(id: "DE0005140008", name: "Deutsche Bank"),
    .init(id: "DE0005190003", name: "BMW"),
    .init(id: "US70450Y1038", name: "Paypal")
]

final class StockViewController: UITableViewController {
    private let disposeBag = DisposeBag()
    private let subscriptionAction = PublishSubject<SubscriptionAction>()
    private lazy var dataSource = makeDataSource()
    private let viewModel: StockViewModel
    
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
        
        [output.stocks.drive(onNext: update),
         output.showAlert.drive(onNext: presentAlert(_:)),
         output.stocksDidUpdate.drive()]
            .forEach({ $0.disposed(by: disposeBag) })
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
