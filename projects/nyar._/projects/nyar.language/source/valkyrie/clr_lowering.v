namespace nyar.language.valkyrie;

using std.io;
using nyar.emitter;

structure LoweredClrModule {
    assembly_name: utf8
    msil: utf8
    console_message: utf8
}

micro append_msil_line(buffer: utf8, line: utf8) -> utf8 {
    return buffer + line + "\n"
}

micro lower_fragment_via_executable_module(submission: FragmentSubmission) -> LoweredClrModule {
    let emit: EmitterResult = emit_clr_from_fragment_submission(submission)
    let assembly_name: utf8 = submission_assembly_name(submission)
    if !emit.ok {
        return LoweredClrModule {
            assembly_name: assembly_name,
            msil: "",
            console_message: emit.error
        }
    }
    let mut msil: utf8 = ""
    msil = append_msil_line(msil, ".assembly extern mscorlib {}")
    msil = append_msil_line(msil, ".assembly extern System.Console {}")
    msil = append_msil_line(msil, ".assembly extern System.Runtime {}")
    msil = append_msil_line(msil, "")
    msil = append_msil_line(msil, ".assembly " + assembly_name + " {}")
    msil = append_msil_line(msil, "")
    msil = msil + emit.msil_text
    return LoweredClrModule {
        assembly_name: assembly_name,
        msil: msil,
        console_message: submission_console_message(submission)
    }
}
