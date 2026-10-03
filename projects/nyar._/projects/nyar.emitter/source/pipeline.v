namespace nyar.emitter;

using nyar.analyzer;
using nyar.optimizer;
using nyar.emitter.clr;
using nyar.emitter.executable;
using nyar.emitter.jvm;
using nyar.emitter.wasm;
using nyar.emitter.wasi;
using std.data.text.msil;

# Isomorphic to the target-private lowering boundary.
# Lanes: CLR / JVM / WASM(+JS glue) / WASI(wasip2|wasip3).
# Target selection and adaptor binding belong to the linker, not this module.
# Do NOT add body_source → backend string bypasses here.

structure EmitterResult {
    ok: bool
    error: utf8
    artifact_path: utf8
    msil_text: utf8
    lane_note: utf8
}

# CLR lane entry — ExecutableModule → typed MSIL (shared with jvm/wasm/wasi input shape).
micro emit_clr_from_mir(module: ExecutableModule) -> EmitterResult {
    if module.functions.length() == 0 {
        return EmitterResult {
            ok: false,
            error: "nyar.emitter.clr: empty ExecutableModule",
            artifact_path: "",
            msil_text: "",
            lane_note: ""
        }
    }
    let typed: TypedMsilModule = lower_executable_module_to_typed_msil(module)
    let mut text: utf8 = ""
    let mut i: usize = 0
    while i < typed.global_methods.length() {
        text = text + render_typed_method_body(typed.global_methods⁅i⁆)
        text = text + "\n"
        i = i + 1
    }
    return EmitterResult {
        ok: true,
        error: "",
        artifact_path: "",
        msil_text: text,
        lane_note: "clr (typed MSIL + named locals)"
    }
}

micro emit_jvm_lane(module: ExecutableModule) -> EmitterResult {
    let note: utf8 = emit_jvm_from_mir(module)
    if note.starts_with("FAIL:") {
        return EmitterResult {
            ok: false,
            error: note,
            artifact_path: "",
            msil_text: "",
            lane_note: "jvm"
        }
    }
    return EmitterResult {
        ok: true,
        error: "",
        artifact_path: "",
        msil_text: "",
        lane_note: note
    }
}

micro emit_wasm_js_lane(module: ExecutableModule) -> EmitterResult {
    let note: utf8 = emit_wasm_js_glue_from_mir(module)
    if note.starts_with("FAIL:") {
        return EmitterResult {
            ok: false,
            error: note,
            artifact_path: "",
            msil_text: "",
            lane_note: "wasm-js"
        }
    }
    return EmitterResult {
        ok: true,
        error: "",
        artifact_path: "",
        msil_text: "",
        lane_note: note
    }
}

micro emit_wasi_lane(module: ExecutableModule, preview: WasiPreview) -> EmitterResult {
    let note: utf8 = emit_wasi_from_mir(module, preview)
    if note.starts_with("FAIL:") {
        return EmitterResult {
            ok: false,
            error: note,
            artifact_path: "",
            msil_text: "",
            lane_note: wasi_preview_name(preview)
        }
    }
    return EmitterResult {
        ok: true,
        error: "",
        artifact_path: "",
        msil_text: "",
        lane_note: note
    }
}

