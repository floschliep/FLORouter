//
//  URLEventHandler.swift
//  FLORouter
//
//  Created by Florian Schliep on 30.04.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import Foundation
import ApplicationServices

@objc(FLOURLEventListener)
public protocol URLEventListener: class {
    func handleURL(_ url: String)
}

/// The global URLEventHandler instance receives URL Events, i.e. when an app is being opened using an URL, and sends them to its listeners.
/// Due to the nature of Apple's API, only one URLEventHandler can exist at a time, which will be the shared instance (global). There are no public initializers.
@objc(FLOURLEventHandler)
public final class URLEventHandler: NSObject {
    
    @objc(globalHandler)
    public static let global = URLEventHandler()
    
// MARK: - Instantiation
    
    private override init() {
        super.init()
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleEvent(_:with:)), forEventClass:  AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }
    
    deinit {
        NSAppleEventManager.shared().removeEventHandler(forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }
    
// MARK: - Event Handling
    
    @objc
    private func handleEvent(_ event: NSAppleEventDescriptor, with replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else { return }
        for listener in self.listeners {
            listener.object?.handleURL(urlString)
        }
    }
    
// MARK: - Listeners
    
    private var listeners = [WeakObject<URLEventListener>]()
    
    /// Adds a listener to the handler.
    ///
    /// - Parameter listener: Listener to add. The handler will keep a weak reference to the listener.
    @objc
    public func addListener(_ listener: URLEventListener) {
        self.listeners.append(WeakObject(object: listener))
    }
    
    /// Removes a listener from the handler.
    ///
    /// - Parameter listener: Listener to remove.
    /// - Returns: Boolean indicating whether the listener was removed or not, meaning it couldn't be found.
    @discardableResult
    @objc
    public func removeListener(_ listener: URLEventListener) -> Bool {
        guard let index = self.listeners.index(where: { $0.object === listener }) else { return false }
        self.listeners.remove(at: index)
        
        return true
    }
    
}

private struct WeakObject<T: AnyObject> {
    private(set) weak var object: T?
    
    init(object: T) {
        self.object = object
    }
}
