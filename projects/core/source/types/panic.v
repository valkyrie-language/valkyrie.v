namespace core::types;

⍝ 不可恢复错误：将消息交给运行时 effect 层处理。
micro panic<T>(message: T): void {
    raise message
}
