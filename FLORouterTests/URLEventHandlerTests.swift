//
//  URLEventHandlerTests.swift
//  FLORouter
//
//  Created by Florian Schliep on 30.04.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import XCTest
@testable import FLORouter

class URLEventHandlerTests: XCTestCase {
    
    func testWeakReferences() {
        weak var weakListener: MockListener? = nil
        autoreleasepool {
            let listener = MockListener()
            URLEventHandler.global.addListener(listener)
            weakListener = listener
            XCTAssertNotNil(weakListener)
        }
        XCTAssertNil(weakListener)
    }
    
    func testEventHandling() {
        let listener = MockListener()
        URLEventHandler.global.addListener(listener)
        
        var url = URL(string: "scheme://")!
        let error = MockSendAppleEvent(with: &url)
        XCTAssertEqual(error, OSErr(noErr))
        XCTAssertNotNil(listener.handledURL)
        XCTAssertEqual(listener.handledURL!, url.absoluteString)
    }
    
    func testRegistration() {
        let listener1 = MockListener()
        let listener2 = MockListener()
        URLEventHandler.global.addListener(listener1)
        URLEventHandler.global.addListener(listener2)
        
        var url = URL(string: "scheme://")!
        let error = MockSendAppleEvent(with: &url)
        XCTAssertEqual(error, OSErr(noErr))
        XCTAssertNotNil(listener1.handledURL)
        XCTAssertNotNil(listener2.handledURL)
    }
    
    func testUnregistration() {
        let listener1 = MockListener()
        let listener2 = MockListener()
        let listener3 = MockListener()
        URLEventHandler.global.addListener(listener1)
        URLEventHandler.global.addListener(listener2)
        URLEventHandler.global.addListener(listener3)
        XCTAssertTrue(URLEventHandler.global.removeListener(listener1))
        XCTAssertTrue(URLEventHandler.global.removeListener(listener3))
        
        var url = URL(string: "scheme://")!
        let error = MockSendAppleEvent(with: &url)
        XCTAssertEqual(error, OSErr(noErr))
        XCTAssertNil(listener1.handledURL)
        XCTAssertNotNil(listener2.handledURL)
        XCTAssertNil(listener3.handledURL)
    }

}

func MockSendAppleEvent(with url: inout URL) -> OSErr {
    let urlDescriptor = NSAppleEventDescriptor(applicationURL: url)
    let event = NSAppleEventDescriptor(eventClass: AEEventClass(kInternetEventClass), eventID: AEEventID(kAEGetURL), targetDescriptor: nil, returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID))
    event.setParam(urlDescriptor, forKeyword: keyDirectObject)
    let error = NSAppleEventManager.shared().dispatchRawAppleEvent(event.aeDesc!, withRawReply: UnsafeMutablePointer(mutating: NSAppleEventDescriptor.null().aeDesc!), handlerRefCon: &url)
    
    return error
}

private class MockListener: URLEventListener {
    private(set) var handledURL: String?
    func handleURL(_ url: String) {
        self.handledURL = url
    }
}
