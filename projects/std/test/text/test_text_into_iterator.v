[test]
micro `test utf8 text into_iterator count and skip`() {
    let value: utf8 = Utf8Text::from_bytes([65, 228, 189, 160, 66])

    if value.into_iterator().count() != 3 {
        panic("utf8 text into_iterator count test failed")
    }

    let mut iter = value.into_iterator().skip(1)
    if !iter.has_next() {
        panic("utf8 text into_iterator skip has_next test failed")
    }

    let first: Option<char> = iter.next()
    if first.is_none() || first.unwrap() as u32 != 0x4F60 {
        panic("utf8 text into_iterator skip first value test failed")
    }

    let second: Option<char> = iter.next()
    if second.is_none() || second.unwrap() as u32 != 0x42 {
        panic("utf8 text into_iterator skip second value test failed")
    }
}

[test]
micro `test utf16 text into_iterator count and skip`() {
    let value: utf16 = "A😀B"

    if value.into_iterator().count() != 3 {
        panic("utf16 text into_iterator count test failed")
    }

    let mut iter = value.into_iterator().skip(1)
    if !iter.has_next() {
        panic("utf16 text into_iterator skip has_next test failed")
    }

    let first: Option<char> = iter.next()
    if first.is_none() || first.unwrap() as u32 != 0x1F600 {
        panic("utf16 text into_iterator skip first value test failed")
    }

    let second: Option<char> = iter.next()
    if second.is_none() || second.unwrap() as u32 != 0x42 {
        panic("utf16 text into_iterator skip second value test failed")
    }
}

[test]
micro `test ascii text into_iterator count and skip`() {
    let value: ascii = AsciiText {
        _bytes: [65, 66, 67]
    }

    if value.into_iterator().count() != 3 {
        panic("ascii text into_iterator count test failed")
    }

    let mut iter = value.into_iterator().skip(2)
    if !iter.has_next() {
        panic("ascii text into_iterator skip has_next test failed")
    }

    let last: Option<char> = iter.next()
    if last.is_none() || last.unwrap() as u32 != 0x43 {
        panic("ascii text into_iterator skip value test failed")
    }
}

[test]
micro `test char ascii alphanumeric`() {
    let digit: char = char::from(57)
    if !digit.is_ascii_digit() || !digit.is_ascii_alphanumeric() {
        panic("char ascii digit test failed")
    }
    if digit.is_ascii_alpha() {
        panic("char digit is not alpha")
    }
    if digit.ascii_alnum_key().unwrap() != 57 {
        panic("char digit alnum key failed")
    }

    let upper: char = char::from(65)
    if !upper.is_ascii_alpha() || !upper.is_ascii_alphanumeric() {
        panic("char ascii upper alpha test failed")
    }
    if upper.ascii_alnum_key().unwrap() != 97 {
        panic("char upper alnum key failed")
    }

    let space: char = char::from(32)
    if space.is_ascii_alphanumeric() {
        panic("char space is not alnum")
    }
    if space.ascii_alnum_key().is_some() {
        panic("char space alnum key should be none")
    }

    let vowel: char = char::from(65)
    if !vowel.is_ascii_vowel() {
        panic("char ascii vowel A failed")
    }
    let consonant: char = char::from(66)
    if consonant.is_ascii_vowel() {
        panic("char B is not vowel")
    }
}

[test]
micro `test char lowercase ascii index`() {
    let s: utf8 = Utf8Text::from_bytes([97, 110, 97])
    loop ch in s {
        let idx: i64 = ch.lowercase_ascii_index().unwrap()
        if idx != 0 && idx != 13 {
            panic("char lowercase ascii index test failed")
        }
    }
}

[test]
micro `test utf8 char_at`() {
    let s: utf8 = Utf8Text::from_bytes([97, 110, 97, 103, 114, 97, 109])
    if s.char_at(0).unwrap().lowercase_ascii_index().unwrap() != 0 {
        panic("utf8 char_at first failed")
    }
    if s.char_at(1).unwrap().lowercase_ascii_index().unwrap() != 13 {
        panic("utf8 char_at second failed")
    }
    if s.char_at(6).is_some() {
        panic("utf8 char_at bounds failed")
    }
}
