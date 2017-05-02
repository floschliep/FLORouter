//
//  RouteComponentTests.swift
//  FLORouter
//
//  Created by Florian Schliep on 02.05.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import XCTest
@testable import FLORouter

class RouteComponentTests: XCTestCase {

    func testBasicPath() {
        FLOAssertRouteComponentsEqual("/very/basic/route/", .path("very"), .path("basic"), .path("route"))
        FLOAssertRouteComponentsEqual("very/basic/route/", .path("very"), .path("basic"), .path("route"))
        FLOAssertRouteComponentsEqual("/very/basic/route", .path("very"), .path("basic"), .path("route"))
        FLOAssertRouteComponentsEqual("very/basic/route", .path("very"), .path("basic"), .path("route"))
    }
    
    func testWildcards() {
        FLOAssertRouteComponentsEqual("test/path/*", .path("test"), .path("path"), .wildcard)
        FLOAssertRouteComponentsEqual("*", .wildcard)
        FLOAssertRouteComponentsNotEqual("test/*/path", .path("test"), .wildcard, .path("path"))
    }
    
    func testPlaceholders() {
        FLOAssertRouteComponentsEqual(":p", .placeholder("p"))
        FLOAssertRouteComponentsEqual("t/:p", .path("t"), .placeholder("p"))
        FLOAssertRouteComponentsEqual("a/::b/:c/d", .path("a"), .placeholder(":b"), .placeholder("c"), .path("d"))
    }
    
    func testWildcardPlaceholderMix() {
        FLOAssertRouteComponentsEqual("my/:route/*", .path("my"), .placeholder("route"), .wildcard)
    }

}

func FLOAssertRouteComponentsEqual(_ route: String, _ components: RouteComponent...) {
    XCTAssertEqual(RouteComponent.components(of: route), components)
}

func FLOAssertRouteComponentsNotEqual(_ route: String, _ components: RouteComponent...) {
    XCTAssertNotEqual(RouteComponent.components(of: route), components)
}

func RouteComponents(_ a: RouteComponent...) -> [RouteComponent] {
    return a
}
