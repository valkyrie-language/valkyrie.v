namespace core::primitive;

trait Eq {
    infix `==`(self, other: Self): bool

    infix `!=`(self, other: Self): bool
}
