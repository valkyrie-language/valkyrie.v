namespace std.operator;

trait Identical {
    infix `===`(self, other: Self): bool

    infix `=!=`(self, other: Self): bool
}
