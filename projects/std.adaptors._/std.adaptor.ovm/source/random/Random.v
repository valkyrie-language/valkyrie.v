namespace std.adaptor.ovm.random;

[host_provider(std::random::Random::new)]
micro host_new() -> std.random.Random {
    return std.random.Random {
        _state: 0
    }
}

[host_provider(std::random::Random::with_seed)]
micro host_with_seed(seed: i32) -> std.random.Random {
    let resolved: i32 = std.random.__random_normalize_seed(seed)
    return std.random.Random {
        _state: resolved
    }
}

[host_provider(std::random::Random::next_i32)]
micro host_next_i32(random: std.random.Random, max_exclusive: i32) -> i32 {
    if random._state != 0 {
        return std.random.__random_fallback_next_i32(random, max_exclusive)
    }

    let value: i32 = std.adaptor.ovm.builtin.math_rand()
    if value < 0 {
        return (-value) % max_exclusive
    }

    return value % max_exclusive
}

[host_provider(std::random::Random::next_f64)]
micro host_next_f64(random: std.random.Random) -> f64 {
    if random._state != 0 {
        return f64(std.random.__random_fallback_next_i32(random, 2147483647)) / 2147483647.0
    }

    return f64(host_next_i32(random, 2147483647)) / 2147483647.0
}
