//
//  ViewController.swift
//  KryptonChallenge
//
//  Created by hrasheed on 22.01.22.
//

import UIKit
import Starscream
import RxRelay

@propertyWrapper
struct EuroFormatter {
    var wrappedValue: String?
}

extension EuroFormatter: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Double.self)

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2

        let number = NSNumber(value: rawValue)
        wrappedValue = formatter.string(from: number)
    }
}

struct Stock {
    let id: String
    var name: String = ""
    
    @EuroFormatter
    var price: String?
    
    init(id: String, name: String, price: String? = "--") {
        self.id = id
        self.name = name
        self.price = price
    }
}

extension Stock: Decodable {
    private enum CodingKeys : String, CodingKey {
        case id = "isin" , price
    }
}

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

struct StockViewModel: Identifiable {
    let id: String
    let name: String
    let price: BehaviorRelay<String?>
    
    init(id: String, name: String, price: String) {
        self.id = id
        self.name = name
        self.price = .init(value: price)
    }
}

extension StockViewModel {
     init(stock: Stock) {
        //self.init(id: stock.id, name: stock.name, price: stock.price)
        self.id = stock.id
        self.name = stock.name
        self.price = .init(value: stock.price)
    }
}

extension StockViewModel: Hashable {
    static func == (lhs: StockViewModel, rhs: StockViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(price.value)
    }
}

import IdentifiedCollections

class StocksTableViewController: UITableViewController, WebSocketDelegate {
    //{"subscribe":"US0378331005"}
    
    //let manager = SocketManager(socketURL: URL(string: "ws://159.89.15.214:8080/")!, config: [.log(true), .compress])
    
    //lazy var socket = manager.defaultSocket
    private lazy var dataSource = makeDataSource()
    var socket: WebSocket!
    
    //var stockViewModels: IdentifiedArrayOf<StockViewModel> = []
    var stockViewModels: [StockViewModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var request = URLRequest(url: URL(string: "ws://159.89.15.214:8080/")!) //https://localhost:8080
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
        tableView.dataSource = dataSource
        update(with: [])
    }
    
    // MARK: - WebSocketDelegate
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            //isConnected = true
            print("websocket is connected: \(headers)")
            //client.write(data: jsonToNSData(json: ["subscribe":"US0378331005"])!)
            //client.write(data: jsonToNSData(json: ["subscribe":"US88160R1014"])!)
            
            //stockViewModels = .init(uniqueElements: stocks.map (StockViewModel.init(stock:)))
            stockViewModels = stocks.map (StockViewModel.init(stock:))
            update(with: stockViewModels)
            
            stocks.forEach {
                jsonToNSData(json: ["subscribe": $0.id]).map { data in
                    client.write(data: data)
                }
            }
        case .disconnected(let reason, let code):
            //isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
            makeStock(from: string).map { stock in
                print("\nmapping: \(stock)\n")
                //stockViewModels[id: $0.id]?.price.accept($0.price)
                stockViewModels.first { $0.id == stock.id }?.price.accept(stock.price)
            }
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            print("connected canncelled")
        case .error(let error):
            print("Error \(error)\n")
            handleError(error)
        }
    }
    
    func handleError(_ error: Error?) {
        if let e = error as? WSError {
            print("websocket encountered an error: \(e.message)")
        } else if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
    }
    
    // Convert from JSON to nsdata
    func jsonToNSData(json: [String: String]) -> Data?{
        do {
            return try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
        } catch let myJSONError {
            print(myJSONError)
        }
        return nil;
    }
    
    func makeStock(from stringData: String) -> Stock? {
        do {
            guard let data = stringData.data(using: .utf8) else {
                      return nil
                  }
            
            
            let stock = try JSONDecoder().decode(Stock.self, from: data)
            
            return stock
        } catch  {
            print(error.localizedDescription)
            return nil
        }
        
    }
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Archive action
        let archive = UIContextualAction(style: .normal,
                                         title: "subscribe") { [weak self] (action, view, completionHandler) in
                                            //self?.handleMoveToArchive()
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

fileprivate extension StocksTableViewController {
    enum Section: CaseIterable {
        case stocks
    }
    
    private func makeDataSource() -> UITableViewDiffableDataSource<Section, StockViewModel> {
        return UITableViewDiffableDataSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, stock in
                let cell = tableView.dequeueReusableCell(withIdentifier: "StockCell", for: indexPath) as? StockCell
                cell?.configure(with: stock)
                return cell
            })
    }
    
    private func update(with stocks: [StockViewModel], animate: Bool = true) {
        DispatchQueue.main.async {
            var snapshot = NSDiffableDataSourceSnapshot<Section, StockViewModel>()
            snapshot.appendSections(Section.allCases)
            snapshot.appendItems(stocks, toSection: .stocks)
            self.dataSource.apply(snapshot, animatingDifferences: animate)
        }
    }
}

import RxSwift
import RxCocoa

class StockCell: UITableViewCell {
    var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
     super.prepareForReuse()
        disposeBag = .init()
    }
    
    func configure(with stock: StockViewModel) {
        textLabel?.text = stock.name
        detailTextLabel.map {
            stock.price.asDriver()
                .drive($0.rx.text)
                .disposed(by: disposeBag)
        }
    }
}
