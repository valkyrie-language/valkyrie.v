using std.text::utf8;
using std.iterator::{Iterator, IntoIterator, FromIterator};
using std.iterator::{all, any, contains, count, find, first, fold, for_each, last, nth, position, reduce};
using std.iterator::{collect, collect_array, collect_array_list};

[test]
micro `test utf8 text into_iterator count and skip`() {
    let value: utf8 = "A你B"

    if value.into_iterator().count() != 3 {
        panic("utf8 text into_iterator count test failed")
    }

    let mut iter = value.into_iterator().skip(1)
    if !iter.has_next() {
        panic("utf8 text into_iterator skip has_next test failed")
    }

    let first: Option<char> = iter.next()
    if first.is_none() || first.unwrap() != '你' {
        panic("utf8 text into_iterator skip first value test failed")
    }

    let second: Option<char> = iter.next()
    if second.is_none() || second.unwrap() != 'B' {
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
    if first.is_none() || first.unwrap() != '😀' {
        panic("utf16 text into_iterator skip first value test failed")
    }

    let second: Option<char> = iter.next()
    if second.is_none() || second.unwrap() != 'B' {
        panic("utf16 text into_iterator skip second value test failed")
    }
}

[test]
micro `test ascii text into_iterator count and skip`() {
    let value: ascii = AsciiText {
        _bytes: [b'A', b'B', b'C']
    }

    if value.into_iterator().count() != 3 {
        panic("ascii text into_iterator count test failed")
    }

    let mut iter = value.into_iterator().skip(2)
    if !iter.has_next() {
        panic("ascii text into_iterator skip has_next test failed")
    }

    let last: Option<char> = iter.next()
    if last.is_none() || last.unwrap() != 'C' {
        panic("ascii text into_iterator skip value test failed")
    }
}

[test]
micro `test char ascii alphanumeric`() {
    let digit: char = '9'
    if !digit.is_ascii_digit() || !digit.is_ascii_alphanumeric() {
        panic("char ascii digit test failed")
    }
    if digit.is_ascii_alpha() {
        panic("char digit is not alpha")
    }

    let upper: char = 'A'
    if !upper.is_ascii_alpha() || !upper.is_ascii_alphanumeric() {
        panic("char ascii upper alpha test failed")
    }
    if upper.to_ascii_lowercase() != 'a' {
        panic("char ascii upper lowercase failed")
    }

    let lower: char = 'z'
    if lower.to_ascii_uppercase() != 'Z' {
        panic("char ascii lower uppercase failed")
    }

    let space: char = ' '
    if space.is_ascii_alphanumeric() {
        panic("char space is not alnum")
    }
}

[test]
micro `test utf8 index read`() {
    let s: utf8 = "anagram"

    # 0 基码点索引（`Cardinal`）：自动取值 `char`，无需 unwrap。
    if (s⁅0⁆) != 'a' {
        panic("utf8 cardinal first failed")
    }

    if (s⁅1⁆) != 'n' {
        panic("utf8 cardinal second failed")
    }

    # 1 基序数索引（`Ordinal`）：7 个码点，第 8 个缺失返回 `None`。
    if s.get(8).is_some() {
        panic("utf8 ordinal bounds failed")
    }
}
