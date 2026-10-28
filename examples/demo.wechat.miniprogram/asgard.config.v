# miniprogram target 维度已删除，由 vendor=wechat 替代 — 此文件已废弃
define_config(asgard) {
    name = "demo.wechat.miniprogram",
        platform = "wechat-miniprogram",
        target = "wasm32-unknown-miniprogram-wasm",
        build {
            output = "dist",
            mode = "dev"
        }
}
