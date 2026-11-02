namespace std.data;

using std.diagnostic::{Error, new_diagnostic, new_span};

# 三段独立 trait 的最小探针（DataFormat 抽象的语言前置）。
# 验证：关联类型声明与引用、impl 侧关联类型绑定、where bound 静态派发。
# trait 层不约束 Settings/Cache 相等：情形 A 绑同一类型，情形 B 绑不同类型，两者都必须成立。

trait ProbeLexer {
    type TokenKind;
    type Settings;
    type Cache;

    micro lex(self, source: DataSource, settings: Settings, cache: Cache) -> DataOutcome<[DataToken<TokenKind>]>
}

trait ProbeParser {
    type TokenKind;
    type Settings;

    micro parse(self, tokens: [DataToken<TokenKind>], settings: Settings) -> DataOutcome<DataCstNode<TokenKind>>
}

trait ProbeBuilder {
    type TokenKind;
    type Ast;
    type Settings;

    micro build(self, node: DataCstNode<TokenKind>, settings: Settings) -> DataOutcome<Ast>
}

# 探针共用的 token kind：root 容器复用 `Word` 作 kind 占位。
unite ProbeTokenKind {
    Word
    Mark
}

# ---- 情形 A：三段 Settings/Cache 绑同一具体类型（正常工程形态） ----

structure ProbeSettingsA {
    base: DataSettings
}


structure ProbeAstA {
    token_count: usize
}

structure ProbeFormatA {
}

imply ProbeFormatA: ProbeLexer {
    type TokenKind = ProbeTokenKind;
    type Settings = ProbeSettingsA;
    type Cache = DataCache<[DataToken<ProbeTokenKind>]>;

    micro lex(self, source: DataSource, settings: ProbeSettingsA, cache: DataCache<[DataToken<ProbeTokenKind>]>) -> DataOutcome<[DataToken<ProbeTokenKind>]> {
        let digest: usize = data_source_digest(source)
        let fingerprint: usize = data_settings_fingerprint(settings.base)
        if data_cache_matches(cache, digest, fingerprint) {
            match cache.value {
                case Filled(payload):
                    return data_outcome_of(payload.value)
                case Empty:
                    panic("matched cache must be filled")
            }
        }
        let tokens: [DataToken<ProbeTokenKind>] = [
            new_data_token::<ProbeTokenKind>(Word, 0, 1),
            new_data_token::<ProbeTokenKind>(Mark, 1, 2)
        ]
        return data_outcome_of(tokens)
    }
}

imply ProbeFormatA: ProbeParser {
    type TokenKind = ProbeTokenKind;
    type Settings = ProbeSettingsA;

    micro parse(self, tokens: [DataToken<ProbeTokenKind>], settings: ProbeSettingsA) -> DataOutcome<DataCstNode<ProbeTokenKind>> {
        let mut children: [DataCstNode<ProbeTokenKind>] = []
        let mut index: usize = 0
        while index < tokens.length() {
            children = children.push(data_cst_token::<ProbeTokenKind>(tokens⁅index⁆))
            index = index + 1
        }
        return data_outcome_of(data_cst_node::<ProbeTokenKind>(Word, new_span(0, 2), children))
    }
}

imply ProbeFormatA: ProbeBuilder {
    type TokenKind = ProbeTokenKind;
    type Ast = ProbeAstA;
    type Settings = ProbeSettingsA;

    micro build(self, node: DataCstNode<ProbeTokenKind>, settings: ProbeSettingsA) -> DataOutcome<ProbeAstA> {
        match node {
            case Node(payload):
                return data_outcome_of(ProbeAstA { token_count: payload.children.length() })
            case Token(payload):
                return data_outcome_partial::<ProbeAstA>(ProbeAstA { token_count: 0 }, [new_diagnostic("probe.builder.root_not_node", Error, "root must be a node", payload.token.span)])
        }
    }
}

# ---- 情形 B：三段绑不同类型（证明 trait 不假设同一） ----

structure ProbeLexSettingsB {
    gap: usize
}

structure ProbeParseSettingsB {
    width: usize
}

structure ProbeBuildSettingsB {
    flag: usize
}

structure ProbeCacheB {
}

structure ProbeAstB {
    token_count: usize
}

structure ProbeLexerB {
}

structure ProbeParserB {
}

structure ProbeBuilderB {
}

imply ProbeLexerB: ProbeLexer {
    type TokenKind = ProbeTokenKind;
    type Settings = ProbeLexSettingsB;
    type Cache = ProbeCacheB;

    micro lex(self, source: DataSource, settings: ProbeLexSettingsB, cache: ProbeCacheB) -> DataOutcome<[DataToken<ProbeTokenKind>]> {
        let tokens: [DataToken<ProbeTokenKind>] = [
            new_data_token::<ProbeTokenKind>(Word, 0, 1),
            new_data_token::<ProbeTokenKind>(Mark, 1, 2)
        ]
        return data_outcome_of(tokens)
    }
}

imply ProbeParserB: ProbeParser {
    type TokenKind = ProbeTokenKind;
    type Settings = ProbeParseSettingsB;

    micro parse(self, tokens: [DataToken<ProbeTokenKind>], settings: ProbeParseSettingsB) -> DataOutcome<DataCstNode<ProbeTokenKind>> {
        let mut children: [DataCstNode<ProbeTokenKind>] = []
        let mut index: usize = 0
        while index < tokens.length() {
            children = children.push(data_cst_token::<ProbeTokenKind>(tokens⁅index⁆))
            index = index + 1
        }
        return data_outcome_of(data_cst_node::<ProbeTokenKind>(Word, new_span(0, 2), children))
    }
}

imply ProbeBuilderB: ProbeBuilder {
    type TokenKind = ProbeTokenKind;
    type Ast = ProbeAstB;
    type Settings = ProbeBuildSettingsB;

    micro build(self, node: DataCstNode<ProbeTokenKind>, settings: ProbeBuildSettingsB) -> DataOutcome<DataCstNode<ProbeTokenKind>> {
        match node {
            case Node(payload):
                return data_outcome_of(ProbeAstB { token_count: payload.children.length() })
            case Token(payload):
                return data_outcome_partial::<ProbeAstB>(ProbeAstB { token_count: 0 }, [new_diagnostic("probe.builder.root_not_node", Error, "root must be a node", payload.token.span)])
        }
    }
}

# ---- 带 trait bound 的泛型调用面 ----

micro probe_lex_run<L>(lexer: L, source: DataSource, settings: L::Settings, cache: L::Cache) -> DataOutcome<[DataToken<L::TokenKind>]>
    where L: ProbeLexer
{
    return lexer.lex(source, settings, cache)
}

micro probe_parse_run<P>(parser: P, tokens: [DataToken<P::TokenKind>], settings: P::Settings) -> DataOutcome<DataCstNode<P::TokenKind>>
    where P: ProbeParser
{
    return parser.parse(tokens, settings)
}

micro probe_build_run<B>(builder: B, node: DataCstNode<B::TokenKind>, settings: B::Settings) -> DataOutcome<B::Ast>
    where B: ProbeBuilder
{
    return builder.build(node, settings)
}

[test]
micro test_probe_shared_settings_binding() -> unit {
    let format: ProbeFormatA = ProbeFormatA {}
    let settings: ProbeSettingsA = ProbeSettingsA { base: new_data_settings(64, 7) }
    let source: DataSource = data_source_from_text("ab")
    let cache: DataCache<[DataToken<ProbeTokenKind>]> = data_cache_empty::<[DataToken<ProbeTokenKind>]>()

    let lexed: DataOutcome<[DataToken<ProbeTokenKind>]> = probe_lex_run(format, source, settings, cache)
    let tokens: [DataToken<ProbeTokenKind>] = data_outcome_value_or(lexed, [])
    let parsed: DataOutcome<DataCstNode<ProbeTokenKind>> = probe_parse_run(format, tokens, settings)
    let cst: DataCstNode<ProbeTokenKind> = data_outcome_value_or(parsed, data_cst_node::<ProbeTokenKind>(Word, new_span(0, 0), []))
    let built: DataOutcome<ProbeAstA> = probe_build_run(format, cst, settings)
    let ast: ProbeAstA = data_outcome_value_or(built, ProbeAstA { token_count: 0 })
    if ast.token_count != 2 {
        panic("shared-settings pipeline should yield two tokens")
    }
}

[test]
micro test_probe_cache_hit_reuses_tokens() -> unit {
    let format: ProbeFormatA = ProbeFormatA {}
    let settings: ProbeSettingsA = ProbeSettingsA { base: new_data_settings(64, 7) }
    let source: DataSource = data_source_from_text("ab")
    let digest: usize = data_source_digest(source)
    let fingerprint: usize = data_settings_fingerprint(settings.base)

    let stored_tokens: [DataToken<ProbeTokenKind>] = [new_data_token::<ProbeTokenKind>(Mark, 0, 1)]
    let cache: DataCache<[DataToken<ProbeTokenKind>]> = data_cache_store(digest, fingerprint, stored_tokens)
    let lexed: DataOutcome<[DataToken<ProbeTokenKind>]> = probe_lex_run(format, source, settings, cache)
    let tokens: [DataToken<ProbeTokenKind>] = data_outcome_value_or(lexed, [])
    if tokens.length() != 1 {
        panic("cache hit must reuse stored token stream")
    }
}

[test]
micro test_probe_distinct_settings_binding() -> unit {
    let lexer: ProbeLexerB = ProbeLexerB {}
    let parser: ProbeParserB = ProbeParserB {}
    let builder: ProbeBuilderB = ProbeBuilderB {}

    let lexed: DataOutcome<[DataToken<ProbeTokenKind>]> = probe_lex_run(
        lexer,
        data_source_from_text("ab"),
        ProbeLexSettingsB { gap: 1 },
        ProbeCacheB {}
    )
    let tokens: [DataToken<ProbeTokenKind>] = data_outcome_value_or(lexed, [])
    let parsed: DataOutcome<DataCstNode<ProbeTokenKind>> = probe_parse_run(parser, tokens, ProbeParseSettingsB { width: 2 })
    let cst: DataCstNode<ProbeTokenKind> = data_outcome_value_or(parsed, data_cst_node::<ProbeTokenKind>(Word, new_span(0, 0), []))
    let built: DataOutcome<ProbeAstB> = probe_build_run(builder, cst, ProbeBuildSettingsB { flag: 3 })
    let ast: ProbeAstB = data_outcome_value_or(built, ProbeAstB { token_count: 0 })
    if ast.token_count != 2 {
        panic("distinct-settings pipeline should yield two tokens")
    }
}
