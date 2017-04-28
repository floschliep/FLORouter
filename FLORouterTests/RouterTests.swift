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
        let id = self.router.register("") { _ in }
        XCTAssertEqual(self.router.handlers.count, 1)
        XCTAssertEqual(self.router.handlers.first!.value.id, id)
    }
    
    /// Test automatic multi registration
    func testMultiRegistration() {
        let ids = self.router.register(["", "", ""]) { _ in }
        XCTAssertEqual(self.router.handlers.count, 3)
        for id in ids {
            XCTAssertTrue(self.router.handlers.contains(where: { $1.id == id }))
        }
    }
    
    /// Test manual registration
    func testManualRegistration() {
        let handler = RouteHandler(route: "", scheme: nil, priority: 0) { _ in }
        let id = self.router.register(handler)
        XCTAssertEqual(self.router.handlers.count, 1)
        XCTAssertEqual(self.router.handlers.first!.key, id)
        XCTAssertEqual(handler.id, id)
    }
    
    /// Test unregistration using IDs
    func testHandlerUnregistration() {
        let id = self.router.register("") { _ in }
        XCTAssertEqual(self.router.handlers.count, 1)
        self.router.unregisterHandler(with: id)
        XCTAssertEqual(self.router.handlers.count, 0)
    }
    
    /// Test unregistration for specific routes with all schemes
    /// Verify other routes are being kept
    /// Verify scheme is ignored for unregistration
    func testRouteUnregistration() {
        let route = "/test"
        self.router.register(route) { _ in }
        self.router.register(route, for: "test1") { _ in }
        let idToKeep = self.router.register("/test2") { _ in }
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
        let idToKeep1 = self.router.register(route) { _ in }
        self.router.register(route, for: scheme) { _ in }
        let idToKeep2 = self.router.register("/test2", for: scheme) { _ in }
        XCTAssertEqual(self.router.handlers.count, 3)
        self.router.unregister(route, for: scheme)
        XCTAssertEqual(self.router.handlers.count, 2)
        XCTAssertTrue(self.router.handlers.contains(where: { $0.key == idToKeep1 }))
        XCTAssertTrue(self.router.handlers.contains(where: { $0.key == idToKeep2 }))
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
