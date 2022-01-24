import Foundation
import Swinject

let defaultStocks: [Stock] = [
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

let DIContainer = AppDIContainer.shared

///`AppDIContainer` is responsible to create/manage all dependencies of the application.
final class AppDIContainer {
    static let shared = AppDIContainer()
    
    // MARK:- Private Properties
    
    private let container = Container()
    
    // MARK:- Init
    
    private init(){
        //Register dependencies
        
        container.register(SocketHandling.self) { _  in SocketHandler() }.inObjectScope(.container)
        container.register(StockUseCase.self) { resolver  in
            guard let handler = resolver.resolve(SocketHandling.self) else {
                fatalError("SocketHandling dependency not found!")
            }
            
            return SocketStockUseCase(handler: handler)
        }.inObjectScope(.container)
        
    }
    
    /// Generic function which will resolve the dependency of type T.
    /// - Returns: object of type T from the container.
    func resolve<T>() -> T {
        guard let object = container.resolve(T.self) else {
            fatalError("Can't resolve dependency of type \(T.self) ")
        }
        
        return object
    }
}
