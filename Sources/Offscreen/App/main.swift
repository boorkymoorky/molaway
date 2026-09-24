import AppKit
import Darwin
import UserNotifications

if CommandLine.arguments.contains("--notifications-probe") {
    UNUserNotificationCenter.current().getDeliveredNotifications { delivered in
        print("delivered=\(delivered.count)")
        exit(0)
    }
    RunLoop.main.run(until: Date().addingTimeInterval(5))
    exit(1)
}

if CommandLine.arguments.contains("--probe") {
    let reading = MediaMonitor.read()
    let camera = CameraStateMonitor.read()
    let focus = FocusMonitor.read()
    let fd = socket(AF_INET, SOCK_STREAM, 0)
    var address = sockaddr_in()
    address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    address.sin_family = sa_family_t(AF_INET)
    address.sin_port = UInt16(9).bigEndian
    address.sin_addr.s_addr = inet_addr("127.0.0.1")
    let result = withUnsafePointer(to: &address) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }
    let networkDenied = result == -1 && (errno == EPERM || errno == EACCES)
    if fd >= 0 { close(fd) }
    print("{\"cameraAvailable\":\(camera != nil),\"cameraActive\":\(camera == true),\"focusAvailable\":\(focus != nil),\"videoAvailable\":\(reading.available),\"videoPlaying\":\(reading.isPlaying),\"idleSeconds\":\(Int(min(1_000_000, max(0, IdleMonitor.idleSeconds().isFinite ? IdleMonitor.idleSeconds() : 0)))),\"networkDenied\":\(networkDenied)}")
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
if let id = Bundle.main.bundleIdentifier,
   let existing = NSRunningApplication.runningApplications(withBundleIdentifier: id).first(where: { $0.processIdentifier != getpid() }) {
    existing.activate()
    exit(0)
}
let delegate = AppDelegate()
app.delegate = delegate
app.run()
