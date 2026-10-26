namespace std.text;

⍝ UTF-16 编码的字符串
[clr("System.Runtime", "System.String")]
[jvm("java.lang.String")]
class Utf16Text {
    _repr: [u16]
}

imply Utf16Text {
    [host_contract]
    micro length(self) -> usize {
        return self._repr.length
    }

    micro is_empty(self) -> bool {
        if self.length() == 0 {
            return true
        }

        return false
    }

    [host_contract]
    micro slice(self, start: usize, count: usize) -> utf16 {
        return self
    }

    [host_contract]
    micro concat(self, other: utf16) -> utf16 {
        return self
    }

    [host_contract]
    micro contains(self, value: utf16) -> bool {
        return false
    }

    [host_contract]
    micro starts_with(self, prefix: utf16) -> bool {
        return false
    }

    [host_contract]
    micro ends_with(self, suffix: utf16) -> bool {
        return false
    }

    [host_contract]
    micro index_of(self, value: utf16) -> Option<usize> {
        return option_none::<usize>()
    }

    [host_contract]
    micro trim(self) -> utf16 {
        return self
    }

    [host_contract]
    micro to_lower(self) -> utf16 {
        return self
    }

    [host_contract]
    micro to_upper(self) -> utf16 {
        return self
    }

    [host_contract]
    micro replace(self, old_value: utf16, new_value: utf16) -> utf16 {
        return self
    }

    [host_contract]
    micro equals(self, other: utf16) -> bool {
        return false
    }

    [host_contract]
    private micro char_at(self, offset: usize) -> u16 {
        return self._repr::[offset]
    }

    micro chars(self) -> Utf16Iterator {
        return Utf16Iterator::new(self)
    }
}

imply Utf16Text: std::iterator::IntoIterator {
    type Item = char;
    type Iter = Utf16Iterator;

    micro into_iterator(self): Utf16Iterator {
        return self.chars()
    }
}

