namespace core::primitive;

⍝ 布尔类型。
⍝ `bool` 表示真与假两种逻辑值。
[primitive("core::primitive::bool")]
structure bool { }

imply bool {
    prefix `!`(self): bool {
        if self {
            return false
        }

        return true
    }

}

imply bool: Eq {
    infix `==`(self, rhs: Self): bool {
        if self {
            return rhs
        }

        return !rhs
    }

    infix `!=`(self, rhs: Self): bool {
        return !(self == rhs)
    }
}

imply bool: Identical {
    infix `===`(self, rhs: Self): bool {
        return self == rhs
    }

    infix `!==`(self, rhs: Self): bool {
        return self != rhs
    }
}
