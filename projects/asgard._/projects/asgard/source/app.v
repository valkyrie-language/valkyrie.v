# Asgard 应用生命周期

using asgard.types

micro create_app(name: string, config: AsgardAppConfig): AsgardApp {
    return AsgardApp {
        name: name
        config: config
        router: AsgardRouter {
            routes: []
        }
        state: AsgardAppState {
            is_running: false
            start_time: 0
            request_count: 0
            error_count: 0
        }
        effects: []
        middlewares: []
    }
}

micro start_app(app: AsgardApp): AsgardApp {
    let state = AsgardAppState {
        is_running: true
        start_time: current_time_ms()
        request_count: 0
        error_count: 0
    }

    let started_router = compile_routes(app.router)

    return AsgardApp {
        name: app.name
        config: app.config
        router: started_router
        state: state
        effects: app.effects
        middlewares: app.middlewares
    }
}

micro stop_app(app: AsgardApp): AsgardApp {
    let state = AsgardAppState {
        is_running: false
        start_time: app.state.start_time
        request_count: app.state.request_count
        error_count: app.state.error_count
    }

    return AsgardApp {
        name: app.name
        config: app.config
        router: app.router
        state: state
        effects: []
        middlewares: app.middlewares
    }
}

micro use_middleware(app: AsgardApp, middleware: AsgardMiddleware): AsgardApp {
    let sorted = sort_by_priority([...app.middlewares, middleware])
    return AsgardApp {
        name: app.name
        config: app.config
        router: app.router
        state: app.state
        effects: app.effects
        middlewares: sorted
    }
}

micro use_plugin(app: AsgardApp, plugin: AsgardPlugin): AsgardApp {
    let mw = AsgardMiddleware {
        name: plugin.name
        priority: 100
        handler: plugin.init_fn
    }
    return use_middleware(app, mw)
}

micro handle_request(app: AsgardApp, request: AsgardRequest): AsgardResponse {
    if (!app.state.is_running) {
        return AsgardResponse {
            status: 503
            headers: {}
            body: "Service Unavailable"
            content_type: "text/plain"
        }
    }

    let route = match_route(app.router, request.path)
    if (route.view_name == "") {
        return AsgardResponse {
            status: 404
            headers: {}
            body: "Not Found"
            content_type: "text/plain"
        }
    }

    let enriched = AsgardRequest {
        method: request.method
        path: request.path
        headers: request.headers
        query: request.query
        body: request.body
        params: route.params
    }

    let response = run_middlewares(app.middlewares, enriched)

    return AsgardResponse {
        status: response.status
        headers: response.headers
        body: response.body
        content_type: response.content_type
    }
}

micro compile_routes(router: AsgardRouter): AsgardRouter {
    return router
}

micro sort_by_priority(middlewares: list): list {
    return middlewares
}

micro run_middlewares(middlewares: list, request: AsgardRequest): AsgardResponse {
    return AsgardResponse {
        status: 200
        headers: {}
        body: ""
        content_type: "text/plain"
    }
}

[js]
micro current_time_ms(): i64
