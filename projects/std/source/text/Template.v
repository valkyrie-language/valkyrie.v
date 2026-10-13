namespace std.text;

# 运行时模板只渲染明确的模板载体；TGrammar 的编译期 template 不属于此协议。
trait Template<Arguments> {
    micro render(self, arguments: Arguments): Result<utf8, TemplateError>
}

# 值的人类可读表示由语言源码实现，不由模板或 backend 按名字猜测。
trait Display {
    micro display(self): utf8
}

unite TemplateError {
    InvalidSyntax { offset: usize },
    ArgumentMismatch { expected: usize, actual: usize },
}
