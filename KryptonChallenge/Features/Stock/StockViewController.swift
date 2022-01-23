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

class StockViewController: UITableViewController {
    private lazy var dataSource = makeDataSource()
    
    var stockViewModels: [StockRowViewModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = dataSource
        update(with: [])
        title = "Krypton Challenge"
        configure()
    }
    
    var disposeBag = DisposeBag()
    let useCase = SocketStockUseCase(handler: handler)
    
    func configure()  {
        useCase.fetchStocks().subscribe {[weak self] event in
            switch event {
            case .next(let stock):
                print(stock)
                self?.stockViewModels.first { $0.id == stock.id }?.price.accept(stock.price)
            case .completed:
                break
            case .error(let error):
                print(error.localizedDescription)
            }
        }.disposed(by: disposeBag)
        
        stockViewModels = stocks.map (StockRowViewModel.init(stock:))
        update(with: stockViewModels)
        
    }
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Archive action
        let archive = UIContextualAction(style: .normal,
                                         title: "subscribe") { [weak self] (action, view, completionHandler) in
            //self?.handleMoveToArchive()
            guard let self = self else { return }
            
            self.useCase.subscribe(stocks[indexPath.row])
                .subscribe {
                    print($0)
                }.disposed(by: self.disposeBag)
            completionHandler(true)
        }
        archive.backgroundColor = .systemGreen
        
        // Trash action
        let trash = UIContextualAction(style: .destructive,
                                       title: "unsubscribe") { [weak self] (action, view, completionHandler) in
            //self?.handleMoveToTrash()
            completionHandler(true)
        }
        trash.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [trash, archive])
        
        return configuration
    }
    
    override func tableView(_ tableView: UITableView,
                            editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
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
    
    private func update(with stocks: [StockRowViewModel], animate: Bool = true) {
        DispatchQueue.main.async {
            var snapshot = NSDiffableDataSourceSnapshot<Section, StockRowViewModel>()
            snapshot.appendSections(Section.allCases)
            snapshot.appendItems(stocks, toSection: .stocks)
            self.dataSource.apply(snapshot, animatingDifferences: animate)
        }
    }
}
