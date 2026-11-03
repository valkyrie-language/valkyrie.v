namespace option_none_probe;

using std.types::{Option, Some};

⍝ `None` 原生形态探针：验证裸 `None` 在显式类型绑定、具体与泛型返回位置、
⍝ 以及 `match` 分支模式中的编译与运行时行为。

micro return_none_concrete() -> Option<i32> {
    return None
}

micro return_none_generic<T>() -> Option<T> {
    return None
}

[main]
micro main(): i32 {
    ⍝ 形态一：显式类型绑定
    let explicit_typed: Option<i32> = None
    if explicit_typed.is_some() {
        return 11
    }
    ⍝ 形态二：具体返回类型的 return 位置
    let from_return = return_none_concrete()
    if from_return.is_some() {
        return 13
    }
    ⍝ 形态三：泛型返回类型的 return 位置
    let from_generic: Option<i32> = return_none_generic::<i32>()
    if from_generic.is_some() {
        return 14
    }
    ⍝ 形态四：match 分支中的 `None` 模式
    let mut code: i32 = 0
    match from_generic {
        case Some(value):
            code = 15
        case None:
            code = 0
    }
    return code
}
