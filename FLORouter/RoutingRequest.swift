//
//  RoutingRequest.swift
//  FLORouter
//
//  Created by Florian Schliep on 28.04.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

import Foundation

public final class RoutingRequest: NSObject, NSCopying {
    
    public let url: URL
    public let scheme: String
    public private(set) var parameters: [String: String?]?
    public private(set) var wildcardComponents: URLComponents?
    
// MARK: - Internal Properties
    
    let pathComponents: [String]
    let queryItems: [URLQueryItem]?
    
// MARK: - Instantiation
    
    public convenience init?(string: String, resolveFragment: Bool = false) {
        guard let url = URL(string: string) else { return nil }
        self.init(url: url, resolveFragment: resolveFragment)
    }
    
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
    
    private init(url: URL, scheme: String, pathComponents: [String], queryItems: [URLQueryItem]?) {
        self.url = url
        self.scheme = scheme
        self.pathComponents = pathComponents
        self.queryItems = queryItems
        super.init()
    }
    
    @available(*, unavailable)
    public override init() {
        fatalError()
    }
    
// MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return type(of: self).init(url: self.url, scheme: self.scheme, pathComponents: self.pathComponents, queryItems: self.queryItems)
    }
    
// MARK: - Actions
    
    public func fulfill(with route: String) -> Bool {
        let routeComponents = route.pathComponents
        var parameters = [String: String?]()
        
        for (index, component) in routeComponents.enumerated() {
            // check if this is a wildcard component
            // we only fulfill wildcards if they're the last component
            if component == "*", index == routeComponents.count-1 {
                if self.pathComponents.count >= index+1 {
                    // we will also fulfill wildcards if it'll be empty…
                    // …so we need to make sure there are enough path components to assemble the wildcard
                    let remainingPath = self.pathComponents[index...self.pathComponents.endIndex-1].joined(separator: "/")
                    self.wildcardComponents = URLComponents(string: remainingPath)
                }
                
                return true
            }

            // make sure we can safely access our URL path components
            guard self.pathComponents.count >= index+1 else { return false }
            
            // fulfill placeholder if needed
            if component.characters.first == ":" {
                let parameterName = String(component.characters.dropFirst())
                parameters[parameterName] = self.pathComponents[index]
                // no need to check for equality here as the component is a placeholder
                continue
            }

            // compare route component to path component
            guard component == self.pathComponents[index] else { return false }
        }
        
        if let queryItems = self.queryItems {
            for item in queryItems {
                parameters[item.name] = (item.value?.characters.count != 0) ? item.value : nil
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
        guard let host = self.percentEncodedHost, host.characters.count > 0, host != "/" else { return }
        // convert the host to "/" so that the host is considered a path component
        self.host = "/"
        self.percentEncodedPath = host.appending(self.percentEncodedPath)
    }
    
    mutating func resolveFragment() {
        // credits to joeldev for his fragment handling: https://github.com/joeldev/JLRoutes/blob/master/JLRoutes/Classes/JLRRouteRequest.m
        // if the URL contains a query or path in the fragment, we will include it in the main path
        // so we can easier handle it later on
        guard let fragment = self.percentEncodedFragment, var fragmentComponents = URLComponents(string: fragment) else { return }
        var path = self.percentEncodedPath
        
        if fragmentComponents.query == nil {
            fragmentComponents.query = fragmentComponents.path
        }
        
        let fragmentContainsQuery: Bool
        if let queryItems = fragmentComponents.queryItems, queryItems.count > 0, let firstItemValue = queryItems[0].value {
            // determine if this fragment is only valid query params and nothing else
            fragmentContainsQuery = (firstItemValue.characters.count > 0)
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
            path = path.appendingFormat("#%@", fragmentComponents.percentEncodedPath)
        }
        
        self.percentEncodedPath = path
    }
    
    var pathComponents: [String] {
        return self.percentEncodedPath.pathComponents
    }
}

extension String {
    var pathComponents: [String] {
        var path = self
        // strip off leading slash so that we don't have an empty first path component
        if path.characters.first == "/" {
            path.characters = path.characters.dropFirst()
        }
        // strip off trailing slash for the same reason
        if path.characters.last == "/" {
            path.characters = path.characters.dropLast()
        }
        
        return path.components(separatedBy: "/")
    }
}
