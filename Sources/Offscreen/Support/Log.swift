import os

enum Log {
    static let app = Logger(subsystem: "local.mola.desktop", category: "app")
    static let engine = Logger(subsystem: "local.mola.desktop", category: "engine")
    static let monitors = Logger(subsystem: "local.mola.desktop", category: "monitors")
    static let windows = Logger(subsystem: "local.mola.desktop", category: "windows")
    static let stats = Logger(subsystem: "local.mola.desktop", category: "stats")
}
