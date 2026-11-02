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
    [constructor]
    MathMatrix {
        rows: [[MathNode]]
    }
    [constructor]
    MathBigOp {
        symbol: utf8
        under: [MathNode]
        over: [MathNode]
    }
    [constructor]
    MathDelimited {
        left: utf8
        right: utf8
        content: [MathNode]
    }
    [constructor]
    MathAligned {
        rows: [[MathNode]]
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

micro math_matrix(rows: [[MathNode]]) -> MathNode {
    return MathMatrix {
        rows: rows
    }
}

micro math_big_op(symbol: utf8, under: [MathNode], over: [MathNode]) -> MathNode {
    return MathBigOp {
        symbol: symbol,
        under: under,
        over: over
    }
}

micro math_delimited(left: utf8, right: utf8, content: [MathNode]) -> MathNode {
    return MathDelimited {
        left: left,
        right: right,
        content: content
    }
}

micro math_aligned(rows: [[MathNode]]) -> MathNode {
    return MathAligned {
        rows: rows
    }
}
