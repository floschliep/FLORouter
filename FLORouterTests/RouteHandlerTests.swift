//
//  RouteHandlerTests.swift
//  FLORouter
//
//  Created by Florian Schliep on 29.04.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import XCTest
@testable import FLORouter

class RouteHandlerTests: XCTestCase {

    func testInitializer() {
        let request = RoutingRequest(string: "scheme://")!
        
        let handler1 = RouteHandler(route: "my/route", scheme: nil, priority: 100) { _ in return false }
        XCTAssertEqual(handler1.route, "my/route")
        XCTAssertEqual(handler1.routeComponents, RouteComponents(.path("my"), .path("route")))
        XCTAssertNil(handler1.scheme)
        XCTAssertEqual(handler1.priority, 100)
        XCTAssertFalse(handler1.action(request))
        
        let handler2 = RouteHandler(route: "my/route2", scheme: "scheme1", priority: 101) { _ in return true }
        XCTAssertEqual(handler2.route, "my/route2")
        XCTAssertEqual(handler2.scheme, "scheme1")
        XCTAssertEqual(handler2.priority, 101)
        XCTAssertTrue(handler2.action(request))
    }
    
    func testHandling() {
        let request1 = RoutingRequest(string: "scheme://my/route")!
        let request2 = RoutingRequest(string: "scheme2://foo/bar")!
        
        let handler1 = RouteHandler(route: "my/route", scheme: nil, priority: 0) { _ in return false }
        XCTAssertFalse(handler1.handle(request: request1))
        
        let handler2 = RouteHandler(route: "my/route", scheme: nil, priority: 0) { _ in return true }
        XCTAssertTrue(handler2.handle(request: request1))
        
        let handler3 = RouteHandler(route: "my/route", scheme: "scheme2", priority: 0) { _ in return true }
        XCTAssertFalse(handler3.handle(request: request1))
        
        let handler4 = RouteHandler(route: "foo/bar", scheme: "scheme2", priority: 0) { _ in return true }
        XCTAssertTrue(handler4.handle(request: request2))
        
        let expectation = self.expectation(description: "A copy of the original request should be passed to the handler action")
        let handler5 = RouteHandler(route: "foo/bar", scheme: nil, priority: 0) { handlerRequest in
            if handlerRequest != request2, handlerRequest.url == request2.url {
                expectation.fulfill()
            }
            
            return true
        }
        XCTAssertTrue(handler5.handle(request: request2))
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }

}
