namespace std.command;

micro render_command_summary_line(cmd: CommandModel) -> utf8 {
    let mut line: utf8 = "  "
    line = line.concat(cmd.name)
    if cmd.description.length() > 0 {
        line = line.concat("  - ")
        line = line.concat(cmd.description)
    }
    line = line.concat("\n")
    return line
}

micro render_argument_help_line(arg: ArgumentDef) -> utf8 {
    let mut line: utf8 = "  "
    line = line.concat(arg.name)
    if arg.required {
        line = line.concat(" (required)")
    }
    if arg.description.length() > 0 {
        line = line.concat("  - ")
        line = line.concat(arg.description)
    }
    line = line.concat("\n")
    return line
}

micro render_option_help_line(opt: OptionDef) -> utf8 {
    let mut line: utf8 = "  --"
    line = line.concat(opt.name)
    if opt.short_name.length() > 0 {
        line = line.concat(", -")
        line = line.concat(opt.short_name)
    }
    if opt.description.length() > 0 {
        line = line.concat("  - ")
        line = line.concat(opt.description)
    }
    line = line.concat("\n")
    return line
}

micro generate_root_help(app_name: utf8, app_description: utf8, commands: [CommandModel]) -> utf8 {
    let mut result: utf8 = app_name
    result = result.concat(" - ")
    result = result.concat(app_description)
    result = result.concat("\n")
    result = result.concat("\n")
    result = result.concat("commands:\n")
    result = result.concat(commands
        .into_iterator()
        .map(micro(cmd: CommandModel) -> utf8 {
            return render_command_summary_line(cmd)
        })
        .reduce("", micro(acc: utf8, line: utf8) -> utf8 {
            return acc.concat(line)
        }))

    result = result.concat("\n")
    result = result.concat("run ")
    result = result.concat(app_name)
    result = result.concat(" <command> --help' for more info.\n")

    return result
}

micro generate_command_help(app_name: utf8, cmd: CommandModel) -> utf8 {
    let mut result: utf8 = "command: "
    result = result.concat(app_name)
    result = result.concat(" ")
    result = result.concat(cmd.name)
    result = result.concat("\n")

    if cmd.description.length() > 0 {
        result = result.concat("\n")
        result = result.concat(cmd.description)
        result = result.concat("\n")
    }

    let cmd_args: [ArgumentDef] = cmd.arguments
    if cmd_args.length() > 0 {
        result = result.concat("\n")
        result = result.concat("arguments:\n")
        result = result.concat(cmd_args
            .into_iterator()
            .map(micro(arg: ArgumentDef) -> utf8 {
                return render_argument_help_line(arg)
            })
            .reduce("", micro(acc: utf8, line: utf8) -> utf8 {
                return acc.concat(line)
            }))
    }

    let cmd_opts: [OptionDef] = cmd.options
    if cmd_opts.length() > 0 {
        result = result.concat("\n")
        result = result.concat("options:\n")
        result = result.concat(cmd_opts
            .into_iterator()
            .map(micro(opt: OptionDef) -> utf8 {
                return render_option_help_line(opt)
            })
            .reduce("", micro(acc: utf8, line: utf8) -> utf8 {
                return acc.concat(line)
            }))
    }

    return result
}

micro generate_usage(app_name: utf8, commands: [CommandModel]) -> utf8 {
    let mut result: utf8 = "usage: "
    result = result.concat(app_name)

    if commands.length() == 0 {
        return result
    }

    result = result.concat(" <")
    result = result.concat(commands
        .into_iterator()
        .map(micro(cmd: CommandModel) -> utf8 {
            return cmd.name
        })
        .reduce("", micro(acc: utf8, name: utf8) -> utf8 {
            if acc.length() == 0 {
                return name
            }

            return acc.concat("|").concat(name)
        }))
    result = result.concat("> [args...]")

    return result
}
