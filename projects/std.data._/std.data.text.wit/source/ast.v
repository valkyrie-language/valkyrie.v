namespace std.data.text.wit;

structure WitDocument {
    package: utf8
    definitions: [WitDefinition]
}

[tag(WitDefinitionKind)]
unite WitDefinition {
    [constructor]
    Interface { value: WitInterfaceDef }
    [constructor]
    World { value: WitWorldDef }
    [constructor]
    TypeDef { value: WitTypeDef }
    [constructor]
    Use { value: WitUseDef }
    [constructor]
    Include { value: WitIncludeDef }
}

structure WitInterfaceDef {
    name: utf8
    types: [WitTypeDef]
    functions: [WitFunctionDef]
    resources: [WitResourceDef]
}

structure WitWorldDef {
    name: utf8
    imports: [WitWorldItem]
    exports: [WitWorldItem]
}

structure WitWorldItem {
    name: utf8
    target: utf8
}

[tag(WitTypeDefKind)]
unite WitTypeDef {
    [constructor]
    Record { name: utf8, fields: [WitField] }
    [constructor]
    Variant { name: utf8, cases: [WitCase] }
    [constructor]
    Enum { name: utf8, values: [utf8] }
    [constructor]
    Flags { name: utf8, values: [utf8] }
    [constructor]
    TypeAlias { name: utf8, target: utf8 }
    [constructor]
    Resource { name: utf8 }
}

structure WitField {
    name: utf8
    type_ref: utf8
}

structure WitCase {
    name: utf8
    type_ref: utf8
}

structure WitFunctionDef {
    name: utf8
    is_static: bool
    is_constructor: bool
    parameters: [WitParam]
    results: [WitResult]
}

structure WitParam {
    name: utf8
    type_ref: utf8
}

structure WitResult {
    name: utf8
    type_ref: utf8
}

structure WitResourceDef {
    name: utf8
}

structure WitUseDef {
    path: utf8
    alias: utf8
}

structure WitIncludeDef {
    path: utf8
}
