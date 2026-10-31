define_config(asgard) {
    name = "asgard_todo",
        target = "wasm32-unknown-browser-wasm",
        entry = "source/app.v",
        html_template = "static/index.html",
        runtime = "boot.js",
        build {
            mode = "prod",
            output = "dist"
        }
}
