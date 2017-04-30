//
//  RouteHandler.swift
//  FLORouter
//
//  Created by Florian Schliep on 28.04.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import Foundation

public typealias RouteHandlerAction = (RoutingRequest) -> Bool
public typealias RouteHandlerID = Int

/// RouteHandler objects encapsulate data which Routers need to match route schemes to actions.
/// When a Router receives a request, it will try to find a handler for it by calling handle(request:) on its registered handlers.
/// You shouldn't store RouteHandler objects yourself but rather register them with a Router.
/// Subclass RouteHandler to perform custom matching in handle(request:).
@objc(FLORouteHandler)
open class RouteHandler: NSObject {
    
    let route: String
    let scheme: String?
    let priority: Int
    let action: RouteHandlerAction
    internal var id: RouteHandlerID
    
// MARK: - Instantiation
    
    /// Instantiate a new handler with the given properties.
    ///
    /// - Parameters:
    ///   - route: Route scheme
    ///   - scheme: Optional scheme name. If nil, all schemes will be matched.
    ///   - priority: Priority of the handler. The higher the priority, the earlier it will be tried to handle.
    ///   - action: Closure which will be called if a request can be handled and was fulfilled.
    public required init(route: String, scheme: String?, priority: Int, action: @escaping RouteHandlerAction) {
        self.route = route
        self.scheme = scheme
        self.priority = priority
        self.action = action
        self.id = -1
        super.init()
    }
    
    @available(*, unavailable)
    public override init() {
        fatalError()
    }
    
// MARK: - Actions
    
    /// Attempts to handle a request.
    ///
    /// - Parameter request: Request to handle. If the scheme matches (or is nil), a copy of the request will be tried to fulfill and passed to the action closure.
    /// - Returns: Boolean indicating whether the request was fulfilled and handled. If true, the Router will stop looking for matching handlers.
    public func handle(request: RoutingRequest) -> Bool {
        if let scheme = self.scheme {
            guard scheme == request.scheme else { return false }
        }
        let request = request.copy() as! RoutingRequest
        guard request.fulfill(with: self.route) else { return false }
        
        return self.action(request)
    }
    
}
