//
//  URLParsingTests.swift
//  FLORouter
//
//  Created by Florian Schliep on 02.05.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import XCTest
@testable import FLORouter

class URLParsingTests: XCTestCase {

    func testMoveHostToPath() {
        var components = URLComponents(string: "scheme://host/path")!
        XCTAssertEqual(components.host, "host")
        XCTAssertEqual(components.path, "/path")
        components.moveHostToPath()
        XCTAssertEqual(components.host, "/")
        XCTAssertEqual(components.path, "host/path")
    }
    
    func testStringPathComponents() {
        XCTAssertEqual("test/path".pathComponents, ["test", "path"])
        XCTAssertEqual("/test/path".pathComponents, ["test", "path"])
        XCTAssertEqual("foo/test/path/".pathComponents, ["foo", "test", "path"])
        XCTAssertEqual("/test/path/bar/".pathComponents, ["test", "path", "bar"])
    }
    
    func testURLComponentsPathComponents() {
        var components = URLComponents(string: "scheme://path/to/resource")!
        components.moveHostToPath()
        XCTAssertEqual(components.pathComponents, ["path", "to", "resource"])
    }
    
    func testFragmentResolutionWithPath() {
        var components = URLComponents(string: "scheme://path/to/resource#/fragment/with/path")!
        components.moveHostToPath()
        XCTAssertEqual(components.pathComponents, ["path", "to", "resource"])
        components.resolveFragment()
        XCTAssertEqual(components.pathComponents, ["path", "to", "resource#", "fragment", "with", "path"])
    }
    
    func testFragmentResolutionWithQuery() {
        var components = URLComponents(string: "scheme://path/to/resource#fragment?foo=bar")!
        XCTAssertNil(components.queryItems)
        components.moveHostToPath()
        components.resolveFragment()
        XCTAssertTrue(components.queryItems!.contains(where: { $0.name == "foo" && $0.value == "bar" }))
    }
    
    func testFragmentResolutionWithPathAndQuery() {
        var components = URLComponents(string: "scheme://path/to/resource#/fragment/path?foo=bar")!
        components.moveHostToPath()
        components.resolveFragment()
        XCTAssertEqual(components.pathComponents, ["path", "to", "resource#", "fragment", "path"])
        XCTAssertTrue(components.queryItems!.contains(where: { $0.name == "foo" && $0.value == "bar" }))
    }

}
