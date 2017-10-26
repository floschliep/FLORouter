//
//  RouterTests.swift
//  RouterTests
//
//  Created by Florian Schliep on 28.04.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import XCTest
@testable import FLORouter

class RouterTests: XCTestCase {
    
    let router = TestRouter()
    
    override func tearDown() {
        super.tearDown()
        self.router.unregisterAll()
    }
    
    /// Test automatic registration
    func testSingleRegistration() {
        let id = self.router.register("") { _ in return false }
        XCTAssertEqual(self.router.handlers.count, 1)
        XCTAssertEqual(self.router.handlers.first!.value.id, id)
    }
    
    /// Test automatic multi registration
    func testMultiRegistration() {
        let ids = self.router.register(["", "", ""]) { _ in return false }
        XCTAssertEqual(self.router.handlers.count, 3)
        for id in ids {
            XCTAssertTrue(self.router.handlers.contains(where: { $1.id == id }))
        }
    }
    
    /// Test manual registration
    func testManualRegistration() {
        let handler = RouteHandler(route: "", scheme: nil, priority: 0) { _ in return false }
        let id = self.router.register(handler)
        XCTAssertEqual(self.router.handlers.count, 1)
        XCTAssertEqual(self.router.handlers.first!.key, id)
        XCTAssertEqual(handler.id, id)
    }
    
    /// Test unregistration using IDs
    func testHandlerUnregistration() {
        let id = self.router.register("") { _ in return false }
        XCTAssertEqual(self.router.handlers.count, 1)
        self.router.unregisterHandler(with: id)
        XCTAssertEqual(self.router.handlers.count, 0)
    }
    
    /// Test unregistration for specific routes with all schemes
    /// Verify other routes are being kept
    /// Verify scheme is ignored for unregistration
    func testRouteUnregistration() {
        let route = "/test"
        self.router.register(route) { _ in return false }
        self.router.register(route, for: "test1") { _ in return false }
        let idToKeep = self.router.register("/test2") { _ in return false }
        XCTAssertEqual(self.router.handlers.count, 3)
        self.router.unregister(route)
        XCTAssertEqual(self.router.handlers.count, 1)
        XCTAssertEqual(self.router.handlers.first!.key, idToKeep)
    }
    
    /// Test unregistration for specific routes with a certain scheme
    /// Verify same route without scheme is being kept
    /// Verify different route with same scheme is being kept
    func testRouteSchemeUnregistration() {
        let route = "/test"
        let scheme = "test1"
        let idToKeep1 = self.router.register(route) { _ in return false }
        self.router.register(route, for: scheme) { _ in return false }
        let idToKeep2 = self.router.register("/test2", for: scheme) { _ in return false }
        XCTAssertEqual(self.router.handlers.count, 3)
        self.router.unregister(route, for: scheme)
        XCTAssertEqual(self.router.handlers.count, 2)
        XCTAssertTrue(self.router.handlers.contains(where: { $0.key == idToKeep1 }))
        XCTAssertTrue(self.router.handlers.contains(where: { $0.key == idToKeep2 }))
    }
    
    func testRoutingPriority() {
        var lastCheckedPriority = 999
        
        func action(withPriority actionPriority: Int) -> ((RoutingRequest) -> Bool) {
            return { _ in
                if lastCheckedPriority < actionPriority {
                    XCTFail("Checked \(lastCheckedPriority) before \(actionPriority)")
                }
                lastCheckedPriority = actionPriority
                
                return false
            }
        }
        
        self.router.register("*", priority: 50, action: action(withPriority: 50))
        self.router.register("*", priority: 100, action: action(withPriority: 100))
        self.router.register("*", priority: 150, action: action(withPriority: 150))
        self.router.register("*", priority: 1, action: action(withPriority: 1))
        self.router.register("*", priority: 0, action: action(withPriority: 0))
        self.router.route(urlString: "scheme://")
    }
    
    func testRoutingStopping() {
        var calledBlock1 = false
        var calledBlock2 = false
        var calledBlock3 = false
        
        self.router.register("*", priority: 100) { _ in
            calledBlock1 = true
            return false
        }
        self.router.register("*", priority: 99) { _ in
            calledBlock2 = true
            return true
        }
        self.router.register("*", priority: 98) { _ in
            calledBlock3 = true
            return true
        }
        self.router.route(urlString: "scheme://")
        
        XCTAssertTrue(calledBlock1)
        XCTAssertTrue(calledBlock2)
        XCTAssertFalse(calledBlock3)
    }
    
    func testIntegration() {
        var url = URL(string: "scheme://test")!
        var calledBlock = false
        self.router.register("/test") { [url = url] (request) in
            XCTAssertEqual(request.url, url)
            calledBlock = true
            
            return true
        }
        _ = MockSendAppleEvent(with: &url)
        XCTAssertTrue(calledBlock)
    }
    
    func testMultipleRouters() {
        let router1 = Router()
        var calledBlock1 = false
        router1.register("/test") { _ in
            calledBlock1 = true
            return true
        }
        
        let router2 = Router()
        var calledBlock2 = false
        router2.register("/test") { _ in
            calledBlock2 = true
            return true
        }
        
        weak var weakRouter3: Router?
        weak var weakHandler3: RouteHandler?
        var calledBlock3 = false
        autoreleasepool {
            let handler3 = RouteHandler(route: "/test", scheme: nil, priority: 0, action: { _ in
                calledBlock3 = true
                return true
            })
            
            let router3 = Router()
            router3.register(handler3)
            
            weakHandler3 = handler3
            weakRouter3 = router3
        }
        
        var url = URL(string: "scheme://test")!
        _ = MockSendAppleEvent(with: &url)
        XCTAssertTrue(calledBlock1)
        XCTAssertTrue(calledBlock2)
        XCTAssertNil(weakRouter3)
        XCTAssertNil(weakHandler3)
        XCTAssertFalse(calledBlock3)
    }
    
}

class TestRouter: Router {
    var usedIDs = [RouteHandlerID]()

    /// Test uniqueness of IDs
    override func register(_ handler: RouteHandler) -> RouteHandlerID {
        let id = super.register(handler)
        defer {
            self.usedIDs.append(id)
        }
        XCTAssertFalse(self.usedIDs.contains(id))
        
        return id
    }
    
}
