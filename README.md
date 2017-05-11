# FLORouter

FLORouter is an URL routing library for macOS. It provides a simple and unified way to handle URL schemes in your Mac app by using a powerful block-based API.

## Usage
#### Simple Registration
```
Router.global.register("/my/route") { request in
	let scheme = request.scheme
	// …
	return true
}
```

This example registers the route `/my/route` for all schemes using the shared `Router` instance `global`. You can retrieve the scheme used to open your app from the supplied `request` object.
#### Multiple Routes
```
let router = Router()
router.register(["/foo/bar", "/bar/foo"]) { request in
	let url = request.url
	// …
	return true
}
```

It’s possible to use multiple `Router` instances simultaneously. Here we create our own instance and register two routes at once which will both be handled by the same block.
#### Scheme Requirements
```
Router.global.register("/", for: "scheme-1") { request in
	// …
	return true
}
Router.global.register("/", for: "scheme-2") { request in
	// …
	return true
}
```

You can also require specific schemes. The first block will only be called for the URL `scheme-1://` and the second for `scheme-2://`.
#### Parameters
```
Router.global.register("/view/:user“) { request in
	let user = request.parameters["user"]
	let referrer = request.parameters["referrer"]
	// …
	return true
}
```

When opening the URL `myapp://view/foo?referrer=bar`, the registered block would reveice `foo` as `user` parameter and `bar` as `referrer` parameter.
#### Wildcards

```
Router.global.register("/unknown/route/*") { request in
	let wildcardComponents = request.wildcardComponents
	// …
	return true 
}
```

In case you don’t know all possible paths beforehand you can register a wildcard route. The URL components found at the position of the wildcard can be retrieved using the `wildcardComponents` property of the `request` object. Be aware that wildcard routes will also me matched if the wildcard is empty. In this case the `wildcardComponents` property will be `nil`.

## Requirements

FLORouter is written in Swift 3 but its public interface is 100% compatible with Objective-C. Requires macOS 10.9 or later.

## Installation

Drop the FLORouter Xcode Project into your workspace and add the framework as a target dependency.

## Author

Florian Schliep

- GitHub: [@floschliep](https://github.com/floschliep)
- Twitter: [@floschliep](https://twitter.com/floschliep)
- Web: [floschliep.com](https://floschliep.com)

## License

FLORouter is available under the MIT license. See the LICENSE.txt file for more info.