//
//  Router.swift
//  FLORouter
//
//  Created by Florian Schliep on 28.04.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import Foundation

/// A Router acts as a storage and manager for RouteHandler objects.
/// You can either register a RouteHandler directly with a Router or implicitly by using the convenience methods.
/// Each registered handler gets assigned a unique RouteHandlerID that identifies the RouteHandler instance during the lifetime of the Router.
/// The Router class is not thread-safe. You should access Router objects from the main thread only.
@objc(FLORouter)
public class Router: NSObject, URLEventListener {
    
    @objc(globalRouter)
    public static let global = Router()
    
    /// Boolean indicating whether the fragments of routed URLs, if existent, should be merged with the path and query of the URL. Will be passed to RoutingRequest objects. Defaults to false.
    @objc
    public var resolveURLFragments = false
    
// MARK: - Instantiation
    
    public override init() {
        super.init()
        URLEventHandler.global.addListener(self)
    }
    
    deinit {
        URLEventHandler.global.removeListener(self)
    }
    
// MARK: - Registration
    
    /// Registers a new handler with the router using the specified properties.
    ///
    /// - Parameters:
    ///   - route: Route scheme
    ///   - scheme: Optional scheme name. If nil, all schemes will be matched.
    ///   - priority: Priority of the handler. The higher the priority, the earlier the action will be called. Defaults to 0.
    ///   - action: Closure which will be called if a routed URL matches the specified route and scheme.
    /// - Returns: A RouteHandlerID you can use to uniquely identify the registered handler. If you need to unregister it later, store it and pass it to unregisterHandler(with:).
    @discardableResult
    @objc(registerRoute:forScheme:priority:action:)
    public func register(_ route: String, for scheme: String? = nil, priority: Int = 0, action: @escaping RouteHandlerAction) -> RouteHandlerID {
        return self.register(RouteHandler(route: route, scheme: scheme, priority: priority, action: action))
    }
    
    /// Registers multiple new handlers with different routes with the router.
    ///
    /// - Parameters:
    ///   - routes: Different routing schemes
    ///   - scheme: Optional scheme name. If nil, all schemes will be matched.
    ///   - priority: Priority of the handlers. The higher the priority, the earlier the action will be called. Defaults to 0.
    ///   - action: Closure which will be called if a routed URL matches the specified route and scheme.
    /// - Returns: An array of RouteHandlerIDs you can use to uniquely identify the registered handlers.
    @discardableResult
    @objc(registerRoutes:forScheme:priority:action:)
    public func register(_ routes: [String], for scheme: String? = nil, priority: Int = 0, action: @escaping RouteHandlerAction) -> [RouteHandlerID] {
        return routes.map { self.register($0, for: scheme, priority: priority, action: action) }
    }
    
    /// Unregisters all handlers.
    @objc(unregisterAllHandlers)
    public func unregisterAll() {
        self.handlers.removeAll()
    }
    
    /// Unregisters a specific handler.
    ///
    /// - Parameter id: ID of the handlers you want to unregister.
    @objc(unregisterHandlerWithID:)
    public func unregisterHandler(with id: RouteHandlerID) {
        self.handlers.removeValue(forKey: id)
    }
    
    /// Unregisters all handlers matching a specific route and scheme.
    ///
    /// - Parameters:
    ///   - route: Route scheme of the handlers you want to unregister.
    ///   - scheme: Optional scheme used to match handlers. If nil, all schemes will be matched.
    @objc(unregisterRoute:forScheme:)
    public func unregister(_ route: String, for scheme: String? = nil) {
        for handler in self.handlers(with: route, for: scheme) {
            self.handlers.removeValue(forKey: handler.id)
        }
    }
    
// MARK: - Handler Management
    
    private(set) var handlers: [RouteHandlerID: RouteHandler] = [:]
    private var currentHandlerIndex = -1
    
    /// Registers a specific handler with the router.
    ///
    /// - Parameter handler: Handler to register.
    /// - Returns:  A RouteHandlerID you can use to uniquely identify the registered handler. If you need to unregister it later, store it and pass it to unregisterHandler(with:).
    @discardableResult
    public func register(_ handler: RouteHandler) -> RouteHandlerID {
        self.currentHandlerIndex += 1
        let id = self.currentHandlerIndex
        self.handlers[id] = handler
        handler.id = id
        
        return id
    }
    
    private func handlers(where predicate: (((RouteHandlerID, RouteHandler)) throws -> Bool)) rethrows -> [RouteHandler] {
        return try self.handlers.filter(predicate).map { $1 }
    }
    
    /// Filters handlers by their routes and optional scheme.
    ///
    /// - Parameters:
    ///   - route: Route scheme the returned handlers will have.
    ///   - scheme: Optional scheme. If nil, all schemes will be matched.
    /// - Returns: Handlers found by using the specified filters.
    private func handlers(with route: String, for scheme: String? = nil) -> [RouteHandler] {
        return self.handlers { _, handler in
            guard route == handler.route else { return false }
            if let scheme = scheme {
                return (handler.scheme == scheme)
            } else {
                return true
            }
        }
    }
    
// MARK: - URL Routing
    
    @objc
    public func handleURL(_ url: String) {
        self.route(urlString: url)
    }
    
    /// Attempts to route a URL.
    ///
    /// - Parameter url: URL to route.
    /// - Returns: Boolean indicating whether the URL could be routed successfully or not.
    @discardableResult
    @objc
    public func route(url: URL) -> Bool {
        guard let request = RoutingRequest(url: url, resolveFragment: self.resolveURLFragments) else { return false }
        return self.route(request: request)
    }
    
    /// Attempts to route a URL with the specified string.
    ///
    /// - Parameter urlString: Valid URL string.
    /// - Returns: Boolean indicating whether an URL wiht the string could be routed successfully or not.
    @discardableResult
    @objc
    public func route(urlString: String) -> Bool {
        guard let request = RoutingRequest(string: urlString, resolveFragment: self.resolveURLFragments) else { return false }
        return self.route(request: request)
    }
    
    /// Attempts to route a request.
    ///
    /// - Parameter request: Request to route.
    /// - Returns: Boolean indicating whether the request could be routed successfully or not.
    @discardableResult
    @objc
    public func route(request: RoutingRequest) -> Bool {
        let handlers = self.handlers.sorted {
            return ($0.1.priority > $1.1.priority)
        }
        for (_, handler) in handlers {
            guard handler.handle(request: request) else { continue }
            return true
        }
        
        return false
    }
    
}
