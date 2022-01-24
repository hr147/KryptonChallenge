//
//  SocketHandler.swift
//  KryptonChallenge
//
//  Created on 23.01.22.
//

import Foundation
import RxSwift
import Starscream

extension WebSocket {
    static let defaultSocket: WebSocket = {
        let baseURL = "ws://159.89.15.214:8080/"
        var request = URLRequest(url: URL(string: baseURL)!)
        request.timeoutInterval = 5
        return WebSocket(request: request)
    }()
}

protocol SocketHandling {
    var rawData: Observable<String> { get }
    func write(jsonData: [String: String]) -> Completable
    var isConnected: Bool { get }
    func connect()
}

final class SocketHandler: SocketHandling {
    enum SocketHandlerError: Error {
        case writeFailed(Error)
        case disconnected
        case connectionFailed(Error?)
    }
    
    lazy var rawData = rawDataSubject.asObservable()
    private let rawDataSubject = PublishSubject<String>()
    private(set) var isConnected = false
    
    private let socket: WebSocket
    
    init(socket: WebSocket = .defaultSocket) {
        self.socket = socket
        self.socket.delegate = self
    }
    
    func connect() {
        socket.connect()
    }
    
    deinit {
        socket.disconnect()
    }
    
    func write(jsonData: [String: String]) -> Completable {
        .create { [socket] observer in
            do {
                let data = try JSONSerialization.data(withJSONObject: jsonData, options: JSONSerialization.WritingOptions.prettyPrinted)
                socket.write(data: data) {
                    observer(.completed)
                }
            } catch {
                observer(.error(SocketHandlerError.writeFailed(error)))
            }
            return  Disposables.create()
        }
    }
}

extension SocketHandler: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected:
            isConnected = true
            print("\n***connected....\n\n")
        case .disconnected:
            isConnected = false
            rawDataSubject.on(.error(SocketHandlerError.disconnected))
        case .text(let string):
            rawDataSubject.on(.next(string))
        case .binary, .pong, .ping:
            break
        case .error(let optional):
            isConnected = false
            rawDataSubject.on(.error(SocketHandlerError.connectionFailed(optional)))
        case .viabilityChanged, .reconnectSuggested:
            break
        case .cancelled:
            isConnected = false
            rawDataSubject.on(.error(SocketHandlerError.disconnected))
        }
    }
}
