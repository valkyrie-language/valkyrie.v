namespace vutex;

# 希腊字母命令名 → 字形（v0 小写集）。未知名返回 `None`（未支持命令）。
micro math_greek_glyph(name: utf8) -> Option<utf8> {
    if name.equals("alpha") {
        return Some("α")
    }
    if name.equals("beta") {
        return Some("β")
    }
    if name.equals("gamma") {
        return Some("γ")
    }
    if name.equals("delta") {
        return Some("δ")
    }
    if name.equals("epsilon") {
        return Some("ε")
    }
    if name.equals("zeta") {
        return Some("ζ")
    }
    if name.equals("eta") {
        return Some("η")
    }
    if name.equals("theta") {
        return Some("θ")
    }
    if name.equals("iota") {
        return Some("ι")
    }
    if name.equals("kappa") {
        return Some("κ")
    }
    if name.equals("lambda") {
        return Some("λ")
    }
    if name.equals("mu") {
        return Some("μ")
    }
    if name.equals("nu") {
        return Some("ν")
    }
    if name.equals("xi") {
        return Some("ξ")
    }
    if name.equals("pi") {
        return Some("π")
    }
    if name.equals("rho") {
        return Some("ρ")
    }
    if name.equals("sigma") {
        return Some("σ")
    }
    if name.equals("tau") {
        return Some("τ")
    }
    if name.equals("upsilon") {
        return Some("υ")
    }
    if name.equals("phi") {
        return Some("φ")
    }
    if name.equals("chi") {
        return Some("χ")
    }
    if name.equals("psi") {
        return Some("ψ")
    }
    if name.equals("omega") {
        return Some("ω")
    }
    return None
}
