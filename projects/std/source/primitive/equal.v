namespace std.primitive;

trait Equal {
    infix `==`(self, other: Self): bool

    infix `!=`(self, other: Self): bool
}
