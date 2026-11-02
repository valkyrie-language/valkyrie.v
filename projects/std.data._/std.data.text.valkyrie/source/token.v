namespace std.data.text.valkyrie;

# Generic lexical token shape for Valkyrie source (`.v`).
# Format-specific token unites (VON/MSIL/WAT/WIT) live in their own packages.

unite TokenKind {
    [constructor]
    Identifier { value: utf8 }
    [constructor]
    Number { value: utf8 }
    [constructor]
    Text { value: utf8 }
    [constructor]
    Punctuation { value: utf8 }
    [constructor]
    Comment { value: utf8 }
    [constructor]
    Whitespace { value: utf8 }
    EndOfFile
}

structure Token {
    kind: TokenKind
    span: TextSpan
}

micro new_token(kind: TokenKind, start: usize, stop: usize) -> Token {
    return Token {
        kind: kind,
        span: TextSpan { start: start, stop: stop }
    }
}

micro token_span(token: Token) -> TextSpan {
    return token.span
}

micro token_is(token: Token, kind: TokenKind) -> bool {
    return token.kind == kind
}
