# Asgard Todo 应用入口
# 注册路由并挂载到 DOM

using asgard_todo.data

[js]
micro asgard_register_route(path: utf8, page_name: utf8): i32

[js]
micro asgard_mount(selector: utf8): i32

[js]
micro asgard_log(msg: utf8): void

# 注册路由
micro register_routes(): void {
    asgard_register_route("/", "todo")
    asgard_register_route("/active", "todo")
    asgard_register_route("/done", "todo")
}

# 应用主入口
[main]
micro main(): unit {
    asgard_log("Asgard Todo 启动")
    register_routes()
    asgard_mount("#app")
    asgard_log("Asgard Todo 启动完成")
}
