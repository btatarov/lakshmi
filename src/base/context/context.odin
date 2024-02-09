package default_context

import "base:runtime"

import "core:log"

when ODIN_DEBUG {
    level := log.Level.Debug
} else {
    level := log.Level.Info
}

@private default_logger: log.Logger

Init :: proc() {
    default_logger = log.create_console_logger(level)
}

Destroy :: proc() {
    log.destroy_console_logger(default_logger)
}

GetDefault :: proc "c" () -> runtime.Context {
    context = runtime.default_context()
    context.logger = default_logger
    return context
}
