namespace core::primitive;

trait Equal {
    infix `==`(self, other: Self): bool

    infix `!=`(self, other: Self): bool
}
