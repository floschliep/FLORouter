//
//  RoutingRequestTests.swift
//  FLORouter
//
//  Created by Florian Schliep on 28.04.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import XCTest
@testable import FLORouter

class RoutingRequestTests: XCTestCase {
    
    func testConvenienceInitializer() {
        XCTAssertNotNil(RoutingRequest(string: "scheme://test"))
        XCTAssertNotNil(RoutingRequest(string: "scheme://test?p=a"))
        XCTAssertNotNil(RoutingRequest(string: "scheme://test#d"))
        XCTAssertNotNil(RoutingRequest(string: "scheme://test#d/e"))
        XCTAssertNotNil(RoutingRequest(string: "scheme://"))
        XCTAssertNotNil(RoutingRequest(string: "scheme://"))
        XCTAssertNil(RoutingRequest(string: "s/t"))
        XCTAssertNil(RoutingRequest(string: ""))
        XCTAssertNil(RoutingRequest(string: "://test"))
    }
    
    func testRequiredInitializer() {
        XCTAssertNotNil(RoutingRequest(url: URL(string: "scheme://test")!, resolveFragment: false))
        XCTAssertNotNil(RoutingRequest(url: URL(string: "scheme://test#fragment/path")!, resolveFragment: true))
        XCTAssertNil(RoutingRequest(url: URL(string: "/file/path.abc")!, resolveFragment: false))
    }
    
    func testBasicFulfillment() {
        let request = RoutingRequest(string: "scheme://my/test/path")!
        XCTAssertTrue(request.fulfill(with: "/my/test/path/"))
        XCTAssertTrue(request.fulfill(with: "/my/test/path"))
        XCTAssertTrue(request.fulfill(with: "my/test/path/"))
        XCTAssertTrue(request.fulfill(with: "my/test/path"))
        XCTAssertFalse(request.fulfill(with: "my/other/path"))
        XCTAssertFalse(request.fulfill(with: "other/path"))
        XCTAssertFalse(request.fulfill(with: "none"))
        XCTAssertFalse(request.fulfill(with: "my/test/path/is/too/long"))
        XCTAssertFalse(request.fulfill(with: "my/test"))
    }
    
    func testPathParsing() {
        let request1 = RoutingRequest(string: "scheme://this/is/a/path")!
        XCTAssertEqual(request1.pathComponents, ["this", "is", "a", "path"])
        
        let request2 = RoutingRequest(string: "scheme://path/to#/fragment?foo=bar", resolveFragment: false)!
        XCTAssertTrue(request2.fulfill(with: "path/to"))
        XCTAssertEqual(request2.pathComponents, ["path", "to"])
        XCTAssertNil(request2.parameters)
        XCTAssertNil(request2.queryItems)
        
        let request3 = RoutingRequest(string: "scheme://path/to#/fragment", resolveFragment: true)!
        XCTAssertEqual(request3.pathComponents, ["path", "to#", "fragment"])
        
        let request4 = RoutingRequest(string: "scheme://path/to#/fragment?foo=bar", resolveFragment: true)!
        XCTAssertTrue(request4.fulfill(with: "path/to#/fragment"))
        XCTAssertEqual(request4.pathComponents, ["path", "to#", "fragment"])
        XCTAssertEqual(request4.parameters!["foo"]!, "bar")
    }
    
    func testWildcardFulfillment() {
        var request = RoutingRequest(string: "scheme://test/path/to/some/resource")!
        
        XCTAssertTrue(request.fulfill(with: "test/path/to/some/resource/*"))
        XCTAssertNil(request.wildcardComponents)
        
        self.copyRequest(request: &request)
        XCTAssertTrue(request.fulfill(with: "test/path/to/some/*"))
        XCTAssertEqual(request.wildcardComponents?.string, "resource")
        
        self.copyRequest(request: &request)
        XCTAssertTrue(request.fulfill(with: "test/path/to/*"))
        XCTAssertEqual(request.wildcardComponents?.string, "some/resource")
        
        self.copyRequest(request: &request)
        XCTAssertTrue(request.fulfill(with: "test/*"))
        XCTAssertEqual(request.wildcardComponents?.string, "path/to/some/resource")
        
        self.copyRequest(request: &request)
        XCTAssertTrue(request.fulfill(with: "*"))
        XCTAssertEqual(request.wildcardComponents?.string, "test/path/to/some/resource")
        
        self.copyRequest(request: &request)
        XCTAssertFalse(request.fulfill(with: "test*"))
        XCTAssertNil(request.wildcardComponents)
        
        self.copyRequest(request: &request)
        XCTAssertFalse(request.fulfill(with: "other/path/*"))
        XCTAssertNil(request.wildcardComponents)
        
        self.copyRequest(request: &request)
        XCTAssertFalse(request.fulfill(with: "test/notpath/*"))
        XCTAssertNil(request.wildcardComponents)
        
        self.copyRequest(request: &request)
        XCTAssertFalse(request.fulfill(with: "test/*/to/*"))
        XCTAssertNil(request.wildcardComponents)
        
        self.copyRequest(request: &request)
        XCTAssertFalse(request.fulfill(with: "test/path/to/some/resource/invalid/*"))
        XCTAssertNil(request.wildcardComponents)
    }
    
    func testQueryFulfillment() {
        let request = RoutingRequest(string: "scheme://test/path?a=b&c=&d=e")!
        XCTAssertTrue(request.fulfill(with: "test/path"))
        XCTAssertEqual(request.parameters!["a"]!, "b")
        XCTAssertNil(request.parameters!["c"] ?? nil)
        XCTAssertEqual(request.parameters!["d"]!, "e")
    }
    
    func testPlaceholderFulfillment() {
        let request1 = RoutingRequest(string: "scheme://user/sample/delete")!
        XCTAssertFalse(request1.fulfill(with: "user/:name/add"))
        XCTAssertTrue(request1.fulfill(with: "user/:name/delete"))
        XCTAssertEqual(request1.parameters!["name"]!, "sample")
        
        let request2 = RoutingRequest(string: "scheme://publish/somepost/now?foo=bar")!
        XCTAssertTrue(request2.fulfill(with: "publish/:post/:time"))
        XCTAssertEqual(request2.parameters!["post"]!, "somepost")
        XCTAssertEqual(request2.parameters!["time"]!, "now")
        XCTAssertEqual(request2.parameters!["foo"]!, "bar")
    }
    
// MARK: - Helpers
    
    func copyRequest(request: inout RoutingRequest) {
        request = request.copy() as! RoutingRequest
    }
    
}

extension RoutingRequest {
    func fulfill(with route: String) -> Bool {
        return self.fulfill(with: RouteComponent.components(of: route))
    }
}
