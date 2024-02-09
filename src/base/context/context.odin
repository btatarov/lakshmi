package default_context

import "base:runtime"

import "core:log"

@private default_logger: log.Logger

Init :: proc() {
    when ODIN_DEBUG {
        log_level := log.Level.Debug
    } else {
        log_level := log.Level.Info
    }
    default_logger = log.create_console_logger(log_level)
    context.logger = default_logger
}

Destroy :: proc() {
    log.destroy_console_logger(default_logger)
}

GetDefault :: proc "c" () -> runtime.Context {
    context = runtime.default_context()
    context.logger = default_logger
    return context
}
