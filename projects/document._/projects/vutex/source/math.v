namespace vutex;

# TeX 数学子集的 AST。递归载荷一律走数组形态（单元素约定）：
# `MathFrac` 的 `numerator`/`denominator` 各恰好 1 项，`MathSqrt.radicand`
# 恰好 1 项，`MathScripts.base` 恰好 1 项。
#
# `MathScripts`：`superscript`/`subscript` 可空（空 = 无该脚本）。

unite MathNode {
    [constructor]
    MathSymbol {
        text: utf8
    }
    [constructor]
    MathRow {
        children: [MathNode]
    }
    [constructor]
    MathFrac {
        numerator: [MathNode]
        denominator: [MathNode]
    }
    [constructor]
    MathSqrt {
        radicand: [MathNode]
    }
    [constructor]
    MathScripts {
        base: [MathNode]
        superscript: [MathNode]
        subscript: [MathNode]
    }
}

micro math_symbol(text: utf8) -> MathNode {
    return MathSymbol {
        text: text
    }
}

micro math_row(children: [MathNode]) -> MathNode {
    return MathRow {
        children: children
    }
}

micro math_frac(numerator: MathNode, denominator: MathNode) -> MathNode {
    return MathFrac {
        numerator: [numerator],
        denominator: [denominator]
    }
}

micro math_sqrt(radicand: MathNode) -> MathNode {
    return MathSqrt {
        radicand: [radicand]
    }
}

micro math_scripts(base: MathNode, superscript: [MathNode], subscript: [MathNode]) -> MathNode {
    return MathScripts {
        base: [base],
        superscript: superscript,
        subscript: subscript
    }
}
