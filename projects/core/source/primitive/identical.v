namespace core::primitive;

trait Identical {
    infix `===`(self, other: Self): bool

    infix `=!=`(self, other: Self): bool
}
