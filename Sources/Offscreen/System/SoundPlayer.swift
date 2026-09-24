import AppKit

final class SoundPlayer {
    private var active: NSSound?
    private var lastTransition = -Double.infinity
    func stop() { active?.stop(); active = nil }
    func play(_ choice: SoundChoice, volume: Double, now: Double, transition: Bool = false) {
        guard choice != .none, volume > 0 else { return }
        if transition { guard now - lastTransition >= 10 else { return }; lastTransition = now }
        let sound: NSSound?
        if choice.generated, let url = Bundle.main.url(forResource: choice.rawValue, withExtension: "wav", subdirectory: "Sounds") {
            sound = NSSound(contentsOf: url, byReference: true)
        } else { sound = NSSound(named: choice.rawValue) }
        stop()
        active = sound
        active?.volume = Float(min(1, max(0, volume)))
        active?.play()
    }
}
