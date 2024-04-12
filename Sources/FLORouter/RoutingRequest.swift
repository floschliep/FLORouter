//
//  RoutingRequest.swift
//  FLORouter
//
//  Created by Florian Schliep on 28.04.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import Foundation

/// A RoutingRequest object represents the request to route an URL.
/// After instantiating a RoutingRequest, it parses the URL and stores its information as well as the URL itself.
/// Matching a request with a route is called fulfillment. When calling fulfill(with:) on RoutingRequest object, the object's URL is being matched with a given route, which the object also uses to get and store more information about the URL.
@objc(FLORoutingRequest)
public final class RoutingRequest: NSObject, NSCopying {
    
    /// URL which was used to open the app
    @objc public let url: URL
    
    /// Scheme of the URL
    @objc public let scheme: String
    
    /// Parameters of the URL. Nil until request was fulfilled. Will contain query parameters as well as fulfilled placeholders.
    @objc public private(set) var parameters: [String: String]?
    
    /// Wildcard component of the URL if a wilcard route was fulfilled
    @objc public private(set) var wildcardComponents: URLComponents?
    
// MARK: - Internal Properties
    
    let pathComponents: [String]
    let queryItems: [URLQueryItem]?
    
// MARK: - Instantiation
    
    /// Instantiate a new request for a given string that represents a valid URL.
    ///
    /// - Parameter string: Valid URL string
    /// - Parameter resolveFragment: Boolean indicating whether the fragment of the URL, if it exists, should be merged with the path and query of the URL.
    /// - Returns: A request which is ready to be fulfilled or nil if the URL could not be parsed or has no scheme.
    @objc
    public convenience init?(string: String, resolveFragment: Bool = false) {
        guard let url = URL(string: string) else { return nil }
        self.init(url: url, resolveFragment: resolveFragment)
    }
    
    /// Instantiate a new request for a given URL.
    ///
    /// - Parameter url: URL used to open the app
    /// - Parameter resolveFragment: Boolean indicating whether the fragment of the URL, if it exists, should be merged with the path and query of the URL.
    /// - Returns: A request which is ready to be fulfilled or nil if the URL could not be parsed or has no scheme.
    @objc
    public init?(url: URL, resolveFragment: Bool) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }
        self.url = url
        
        guard let scheme = components.scheme else { return nil }
        self.scheme = scheme
        
        components.moveHostToPath() // otherwise xx:///xxx would be required in order for paths to work correctly
        if resolveFragment {
            components.resolveFragment()
        }
        self.pathComponents = components.pathComponents
        self.queryItems = components.queryItems
        
        super.init()
    }
    
    /// Private initializer used for copying without unnecessary validation or parsing
    private init(url: URL, scheme: String, pathComponents: [String], queryItems: [URLQueryItem]?) {
        self.url = url
        self.scheme = scheme
        self.pathComponents = pathComponents
        self.queryItems = queryItems
        super.init()
    }
    
    @available(*, unavailable)
    @objc
    public override init() {
        fatalError()
    }
    
// MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return type(of: self).init(url: self.url, scheme: self.scheme, pathComponents: self.pathComponents, queryItems: self.queryItems)
    }
    
// MARK: - Actions
    
    /// Fulfill the request with a given route. A request should only be fulfilled once. Make a copy of the request if appropriate.
    /// The URL's scheme will be ignored here.
    ///
    /// - Parameter route: Route for which the request should be fulfilled. May contain a wildcard (*) at the end or placeholders (:abc) anywhere.
    /// - Returns: Boolean indicating whether the given route was able to fulfill the request.
    func fulfill(with routeComponents: [RouteComponent]) -> Bool {
        var parameters = [String: String]()
        // we keep track of the remaining route components while iterating through the path components
        var remainingRouteComponents = routeComponents
        
        pathLoop: for (index, component) in self.pathComponents.enumerated() {
            guard routeComponents.count >= index+1 else { return false }
            let routeComponent = routeComponents[index]
            remainingRouteComponents.remove(at: 0)
            
            switch routeComponent {
            case .path(let name):
                guard name == component else { return false }
            case .placeholder(let name):
                parameters[name] = component
            case .wildcard:
                let remainingPath = self.pathComponents[index...self.pathComponents.endIndex-1].joined(separator: "/")
                self.wildcardComponents = URLComponents(string: remainingPath)
                break pathLoop
            }
        }
        
        if remainingRouteComponents.count > 0 {
            // if there is a remaining route component, it needs to be a wildcard
            // wildcards may only ever be at the end of a route…
            // …so it is only valid if there's just this one wildcard left
            guard remainingRouteComponents.count == 1, case .wildcard = remainingRouteComponents[0] else { return false }
            // if the wildcard is positioned after the path, there's no need to set the wildcardComponents as it would be empty
        }
        
        if let queryItems = self.queryItems {
            for item in queryItems {
                guard let value = item.value, !value.isEmpty else { continue }
                parameters[item.name] = value
            }
        }
        
        if parameters.count != 0 {
            self.parameters = parameters
        }
        
        return true
    }
    
}

// MARK: - URLComponents Extension

extension URLComponents {
    mutating func moveHostToPath() {
        guard let host = self.host, !host.isEmpty, host != "/" else { return }
        // convert the host to "/" so that the host is considered a path component
        self.host = "/"
        self.path = host.appending(self.path)
    }
    
    mutating func resolveFragment() {
        // credits to joeldev for his fragment handling: https://github.com/joeldev/JLRoutes/blob/master/JLRoutes/Classes/JLRRouteRequest.m
        // if the URL contains a query or path in the fragment, we will include it in the main path
        // so we can easier handle it later on
        guard let fragment = self.fragment, var fragmentComponents = URLComponents(string: fragment) else { return }
        var path = self.path
        
        if fragmentComponents.query == nil {
            fragmentComponents.query = fragmentComponents.path
        }
        
        let fragmentContainsQuery: Bool
        if let queryItems = fragmentComponents.queryItems, queryItems.count > 0, let firstItemValue = queryItems[0].value {
            // determine if this fragment is only valid query params and nothing else
            fragmentContainsQuery = !firstItemValue.isEmpty
        } else {
            fragmentContainsQuery = false
        }
        
        if fragmentContainsQuery {
            // include fragment query params in with the standard set
            var queryItems = self.queryItems ?? []
            queryItems.append(contentsOf: fragmentComponents.queryItems!) // force-unwrapping is safe here, the flag would be false otherwise
            self.queryItems = queryItems
        }
        
        if !fragmentContainsQuery || fragmentComponents.path != fragmentComponents.query {
            // handle fragment by include fragment path as part of the main path
            path = path.appendingFormat("#%@", fragmentComponents.path)
        }
        
        self.path = path
    }
    
    var pathComponents: [String] {
        return self.path.pathComponents
    }
}

extension String {
    var pathComponents: [String] {
        var path = self
        // strip off leading slash so that we don't have an empty first path component
        if path.first == "/" {
            path = String(path.dropFirst())
        }
        // strip off trailing slash for the same reason
        if path.last == "/" {
            path = String(path.dropLast())
        }
        
        return path.components(separatedBy: "/")
    }
}
