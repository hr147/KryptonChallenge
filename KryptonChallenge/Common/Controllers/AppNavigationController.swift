import UIKit

final class AppNavigationController: UINavigationController {
    // MARK: - Public Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Private Methods
    
    private func configureUI() {
        navigationBar.barTintColor = .init(color: .standard(.themeColor))
        navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        navigationBar.titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.white,
             NSAttributedString.Key.font: UIFont(.avenirDemiBold, size: .standard(.h3))]
        navigationBar.backgroundColor = .init(color: .standard(.themeColor))
    }
}
