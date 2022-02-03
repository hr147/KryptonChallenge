import UIKit
import RxSwift
import RxCocoa

final class StockTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = .init()
    }
    
    func configure(with stock: StockRowViewModel) {
        textLabel?.text = stock.name
        detailTextLabel.map {
            stock.valueDidChange.asDriver()
                .drive($0.rx.text)
                .disposed(by: disposeBag)
        }
    }
}
