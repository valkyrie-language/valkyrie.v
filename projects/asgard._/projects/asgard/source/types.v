# Asgard 核心类型定义

struct AsgardApp {
    name: string
    config: AsgardAppConfig
    router: AsgardRouter
    state: AsgardAppState
    effects: list
    middlewares: list
}

struct AsgardAppState {
    is_running: bool
    start_time: i64
    request_count: i64
    error_count: i64
}

struct AsgardAppConfig {
    project_type: string
    target: string
    environment: string
    server: AsgardServerConfig
    build: AsgardBuildConfig
    hot_reload: AsgardHotReloadConfig
}

struct AsgardServerConfig {
    host: string
    port: int
    workers: int
    timeout: int
    cors: bool
    cors_origins: list
}

struct AsgardBuildConfig {
    output: string
    minify: bool
    sourcemap: bool
    optimization: string
    ssr: bool
    pwa: bool
}

struct AsgardHotReloadConfig {
    enabled: bool
    debounce_ms: int
    watch_extensions: list
}

struct AsgardRequest {
    method: string
    path: string
    headers: map
    query: map
    body: string
    params: map
}

struct AsgardResponse {
    status: int
    headers: map
    body: string
    content_type: string
}

struct AsgardMiddleware {
    name: string
    priority: int
    handler: string
}

struct AsgardPlugin {
    name: string
    version: string
    init_fn: string
    destroy_fn: string
}

enum AsgardEnvironment {
    Development
    Staging
    Production
    Test
}

enum AsgardProjectType {
    Frontend
    Backend
    Fullstack
    Library
}
