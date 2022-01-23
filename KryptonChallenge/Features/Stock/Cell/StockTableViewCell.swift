//
//  StockTableViewCell.swift
//  KryptonChallenge
//
//  Created on 23.01.22.
//

import UIKit
import RxSwift
import RxCocoa

class StockTableViewCell: UITableViewCell {
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
