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

open class RouteHandler: NSObject {
    
    let route: String
    let scheme: String?
    let priority: Int
    let action: RouteHandlerAction
    internal var id: RouteHandlerID
    
    public init(route: String, scheme: String?, priority: Int, action: @escaping RouteHandlerAction) {
        self.route = route
        self.scheme = scheme
        self.priority = priority
        self.action = action
        self.id = -1
        super.init()
    }
    
    public func handle(request: RoutingRequest) -> Bool {
        if let scheme = self.scheme, scheme != request.scheme {
            return false
        }
        guard request.fulfill(with: self.route) else { return false }
        
        return self.action(request)
    }
    
}
