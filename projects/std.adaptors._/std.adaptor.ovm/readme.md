# `std.adaptor.ovm`

Valkyrie OVM 平台 SDK — 提供 OVM 指令集绑定，编译为 `.nyar` 字节码。
## 目标三元组
| 目标三元组            | 架构   | 说明              |
|:-----------------------|:-------|:------------------|
| `ovm-unknown-unknown-managed` | ovm | OVM 通用运行时 |

## 包内容
```
std.adaptor.ovm/
├── legion.von          # 包清单
└── source/
    ├── arith.v         # 算术运算 [ovm] 宿主绑定
    ├── builtin.v       # VM 内置函数 [ovm] 宿主绑定
    ├── cmp.v           # 比较运算 [ovm] 宿主绑定
    ├── control.v       # 控制流 [ovm] 宿主绑定
    ├── conv.v          # 类型转换 [ovm] 宿主绑定
    ├── memory.v        # 内存操作 [ovm] 宿主绑定
    ├── object.v        # 对象操作 [ovm] 宿主绑定
    └── utf8.v        # 字符串操作 [ovm] 宿主绑定
```

## 绑定概念

| 文件        | 绑定类型                      | 说明                                 |
|:------------|:------------------------------|:-------------------------------------|
| `arith.v`   | `[ovm("i32_add/...")]`         | i32/i64/f64 算术与位运算宿主绑定 |
| `builtin.v` | `[ovm("println/...")]`         | OVM 内置函数绑定                  |
| `cmp.v`     | `[ovm("i32_eq/...")]`          | i32 比较宿主绑定                 |
| `control.v` | `[ovm("nop")]`                 | 控制流宿主绑定                   |
| `conv.v`    | `[ovm("i32_to_...")]`          | 类型转换宿主绑定                 |
| `memory.v`  | `[ovm("alloc/...")]`           | 内存管理宿主绑定                 |
| `object.v`  | `[ovm("obj_.../closure_...")]` | 对象与闭包宿主绑定               |
| `utf8.v`  | `[ovm("str_...")]`             | 字符串操作宿主绑定               |

## 与其他适配器的关系

`std.adaptor.ovm` 是 OVM 平台的适配层，与其他平台适配器并列：

| 适配器              | 平台        | 绑定属性          |
|:---------------------|:------------|:-------------------|
| `std.adaptor.ovm`   | OVM      | `[ovm]`            |
| `std.adaptor.wasm`   | WebAssembly | `[js_builtin]`     |
| `std.adaptor.dotnet` | .NET CLR    | `[dotnet_builtin]` |
| `std.adaptor.jvm`    | JVM         | `[jvm_builtin]`    |
| ...                  | ...         | ...                |

`valkyrie-core` 提供与运行时无关的纯 GGScript 实现和抽象声明， 各平台适配器提供对应运行时的具体绑定。
## 编译命令

```bash
# 编译为 OVM 字节码
vcc build --target ovm

# 编译为 OVM 并运行
vcc run --target ovm
```

## 状态
✅ OVM 宿主绑定已覆盖 8 个模块，包含 50+ `[ovm]` 绑定。
