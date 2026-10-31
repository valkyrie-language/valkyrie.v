# Asgard 路由系统

using asgard.types

struct AsgardRouter {
    routes: list
    compiled: bool
    pattern_cache: map
}

struct AsgardRoute {
    path: string
    view_name: string
    params: list
    method: string
    guard: string
    route_meta: map
}

struct AsgardRouteMatch {
    found: bool
    route: AsgardRoute
    params: map
    query: map
}

struct MatchResult {
    matched: bool
    params: map
}

micro create_router(): AsgardRouter {
    return AsgardRouter {
        routes: []
        compiled: false
        pattern_cache: {}
    }
}

micro register_route(router: AsgardRouter, path: string, view_name: string): AsgardRouter {
    return register_route_with_method(router, path, view_name, "GET")
}

micro register_route_with_method(router: AsgardRouter, path: string, view_name: string, method: string): AsgardRouter {
    let route = AsgardRoute {
        path: path
        view_name: view_name
        params: extract_params(path)
        method: method
        guard: ""
        route_meta: {}
    }

    return AsgardRouter {
        routes: [...router.routes, route]
        compiled: false
        pattern_cache: router.pattern_cache
    }
}

micro register_guarded_route(router: AsgardRouter, path: string, view_name: string, method: string, guard: string): AsgardRouter {
    let route = AsgardRoute {
        path: path
        view_name: view_name
        params: extract_params(path)
        method: method
        guard: guard
        route_meta: {}
    }

    return AsgardRouter {
        routes: [...router.routes, route]
        compiled: false
        pattern_cache: router.pattern_cache
    }
}

micro match_route(router: AsgardRouter, path: string): AsgardRoute {
    let result = match_route_full(router, path, "GET")
    if (result.found) {
        return result.route
    }

    return AsgardRoute {
        path: path
        view_name: ""
        params: []
        method: ""
        guard: ""
        route_meta: {}
    }
}

micro match_route_full(router: AsgardRouter, path: string, method: string): AsgardRouteMatch {
    let segments = split_path(path)

    loop route in router.routes {
        if (route.method != "" && route.method != method) {
            continue
        }

        let route_segments = split_path(route.path)
        if (length(segments) != length(route_segments)) {
            continue
        }

        let match_result = match_segments(route_segments, segments)
        if (match_result.matched) {
            return AsgardRouteMatch {
                found: true
                route: route
                params: match_result.params
                query: {}
            }
        }
    }

    return AsgardRouteMatch {
        found: false
        route: AsgardRoute {
            path: ""
            view_name: ""
            params: []
            method: ""
            guard: ""
            route_meta: {}
        }
        params: {}
        query: {}
    }
}

micro extract_params(path: string): list {
    let segments = split_path(path)
    let params = []
    loop seg in segments {
        if (starts_with(seg, ":")) {
            params = [...params, substring(seg, 1)]
        }
    }
    return params
}

micro split_path(path: string): list {
    if (path == "/") {
        return []
    }

    let trimmed = trim_slashes(path)
    return split_by(trimmed, "/")
}

micro match_segments(pattern: list, actual: list): MatchResult {
    let params = {}
    let i = 0

    while (i < length(pattern)) {
        let pat = pattern[i]
        let act = actual[i]

        if (starts_with(pat, ":")) {
            let param_name = substring(pat, 1)
            params[param_name] = act
        } else {
            if (pat != act) {
                return MatchResult {
                    matched: false
                    params: {}
                }
            }
        }

        i = i + 1
    }

    return MatchResult {
        matched: true
        params: params
    }
}

[js]
micro starts_with(s: string, prefix: string): bool

[js]
micro substring(s: string, start: i32): string

[js]
micro trim_slashes(s: string): string

[js]
micro split_by(s: string, delimiter: string): list

[js]
micro length(lst: list): i32
