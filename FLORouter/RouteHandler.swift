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
    
    @objc public let route: String
    @objc public let scheme: String?
    @objc public let priority: Int
    @objc public let action: RouteHandlerAction
    
    var id: RouteHandlerID
    let routeComponents: [RouteComponent]
    
// MARK: - Instantiation
    
    /// Instantiate a new handler with the given properties.
    ///
    /// - Parameters:
    ///   - route: Route scheme
    ///   - scheme: Optional scheme name. If nil, all schemes will be matched.
    ///   - priority: Priority of the handler. The higher the priority, the earlier it will be tried to handle.
    ///   - action: Closure which will be called if a request can be handled and was fulfilled.
    @objc
    public required init(route: String, scheme: String?, priority: Int, action: @escaping RouteHandlerAction) {
        self.route = route
        self.scheme = scheme
        self.priority = priority
        self.action = action
        self.id = -1
        self.routeComponents = RouteComponent.components(of: route)
        super.init()
    }
    
    @available(*, unavailable)
    @objc
    public override init() {
        fatalError()
    }
    
// MARK: - Actions
    
    /// Attempts to handle a request.
    ///
    /// - Parameter request: Request to handle. If the scheme matches (or is nil), a copy of the request will be tried to fulfill and passed to the action closure.
    /// - Returns: Boolean indicating whether the request was fulfilled and handled. If true, the Router will stop looking for matching handlers.
    @objc
    public func handle(request: RoutingRequest) -> Bool {
        if let scheme = self.scheme {
            guard scheme == request.scheme else { return false }
        }
        let request = request.copy() as! RoutingRequest
        guard request.fulfill(with: self.routeComponents) else { return false }
        
        return self.action(request)
    }
    
}

enum RouteComponent {
    case path(String)
    case placeholder(String)
    case wildcard
    
    static func components(of route: String) -> [RouteComponent] {
        let pathComponents = route.pathComponents
        var components = [RouteComponent]()
        
        for (index, component) in pathComponents.enumerated() {
            // check if this is a wildcard
            if component == "*", index == pathComponents.count-1 {
                components.append(.wildcard)
                break
            }
            
            // check if this is a placeholder
            if component.first == ":" {
                let parameterName = String(component.dropFirst())
                components.append(.placeholder(parameterName))
                continue
            }
            
            // normal path component
            components.append(.path(component))
        }
        
        return components
    }
}

extension RouteComponent: Equatable {
    static func ==(lhs: RouteComponent, rhs: RouteComponent) -> Bool {
        switch lhs {
        case .path(let lhsName):
            guard case .path(let rhsName) = rhs else { return false }
            return (lhsName == rhsName)
        case .placeholder(let lhsName):
            guard case .placeholder(let rhsName) = rhs else { return false }
            return (lhsName == rhsName)
        case .wildcard:
            guard case .wildcard = rhs else { return false }
            return true
        }
    }
}
