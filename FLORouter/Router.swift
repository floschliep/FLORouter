//
//  Router.swift
//  FLORouter
//
//  Created by Florian Schliep on 28.04.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import Foundation

public class Router: NSObject {
    
    @objc(globalRouter)
    public static let global = Router()
    
// MARK: - Instantiation
    
    public override init() {
        super.init()
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleEvent(_:with:)), forEventClass: UInt32(kInternetEventClass), andEventID: UInt32(kAEGetURL))
    }
    
    deinit {
        NSAppleEventManager.shared().removeEventHandler(forEventClass: UInt32(kInternetEventClass), andEventID: UInt32(kAEGetURL))
    }
    
// MARK: - Registration
    
    @discardableResult
    @objc(registerRoute:forScheme:priority:action:)
    public func register(_ route: String, for scheme: String? = nil, priority: Int = 0, action: @escaping RouteHandlerAction) -> RouteHandlerID {
        return self.register(RouteHandler(route: route, scheme: scheme, priority: priority, action: action))
    }
    
    @discardableResult
    @objc(registerRoutes:forScheme:priority:action:)
    public func register(_ routes: [String], for scheme: String? = nil, priority: Int = 0, action: @escaping RouteHandlerAction) -> [RouteHandlerID] {
        return routes.map { self.register($0, for: scheme, priority: priority, action: action) }
    }
    
    public func unregisterAll() {
        self.handlers.removeAll()
    }
    
    public func unregisterHandler(with id: RouteHandlerID) {
        self.handlers.removeValue(forKey: id)
    }
    
    public func unregister(_ route: String, for scheme: String? = nil) {
        for handler in self.handlers(with: route, for: scheme) {
            self.handlers.removeValue(forKey: handler.id)
        }
    }
    
// MARK: - Handler Management
    
    private var handlers: [Int: RouteHandler] = [:]
    private var currentHandlerIndex = -1
    
    @discardableResult
    public func register(_ handler: RouteHandler) -> RouteHandlerID {
        self.currentHandlerIndex += 1
        let id = self.currentHandlerIndex
        self.handlers[id] = handler
        handler.id = id
        
        return id
    }
    
    private func handlers(with route: String, for scheme: String? = nil) -> [RouteHandler] {
        return self.handlers.filter({ _, handler in
            guard route == handler.route else { return false }
            if let scheme = scheme {
                return (handler.scheme == scheme)
            } else {
                return true
            }
        }).map({ $1 })
    }
    
    
// MARK: - URL Handling
    
    @objc
    private func handleEvent(_ event: NSAppleEventDescriptor, with replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: UInt32(keyDirectObject))?.stringValue else { return }
        guard let url = URL(string: urlString) else { return }
        
        
    }
    
}
