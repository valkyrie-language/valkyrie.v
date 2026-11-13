# Windows desktop UiHost

namespace asgard.ui.windows;

using asgard.ui.host;
using asgard.ui.wire;
using asgard.ui.ir;
using asgard.ui.runtime;
using std.text::Utf8DecodeError;
using std.types::{Result, Fine};

class WindowsUiHost {
    executable: [u8]
    tree: ViewTreeState
}

micro windows_host_from_executable(exe: [u8]): WindowsUiHost {
    return WindowsUiHost { executable: exe, tree: create_view_tree() }
}

micro windows_load_ir(host: WindowsUiHost): Result<[UiComponent], Utf8DecodeError> {
    let section: [u8] = find_asgard_ui_section(host.executable)
    if section.length == 0 {
        return Fine { value: [] }
    }
    return decode_package(section)
}

imply WindowsUiHost: UiHost {
    micro mount(mut self, component: UiComponent): unit {
        let _summary: utf8 = component_summary(component)
    }

    micro patch(mut self, key: utf8, value: utf8): unit {
        let _k: utf8 = key
        let _v: utf8 = value
    }

    micro on_event(mut self, name: utf8): unit {
        let _n: utf8 = name
    }
}
