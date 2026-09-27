import Foundation
import Testing
@testable import Offscreen

@Suite struct PauseTests {
    private func calendar(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }
    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
    private func file() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("pause.json")
    }

    @Test func fixedDurationsAndManualResume() {
        let url = file(), now = Date(timeIntervalSince1970: 1_000_000)
        var pause = PauseModel(fileURL: url, now: now)
        pause.select(.thirtyMinutes, now: now)
        #expect(pause.manual == .until(now.addingTimeInterval(1800)))
        pause.expire(now: now.addingTimeInterval(1799))
        #expect(pause.isManuallyPaused)
        pause.expire(now: now.addingTimeInterval(1800))
        #expect(!pause.isManuallyPaused)
        pause.select(.oneHour, now: now)
        #expect(pause.manual == .until(now.addingTimeInterval(3600)))
        pause.select(.untilResumed, now: now)
        pause.expire(now: now.addingTimeInterval(86400 * 30))
        #expect(pause.manual == .untilResumed)
        pause.resumeManually()
        #expect(!pause.isPaused)
    }

    @Test func nextLocalNineHandlesTimeZonesAndDaylightSaving() {
        for zone in ["Europe/Istanbul", "America/New_York", "Asia/Tokyo"] {
            let local = calendar(zone)
            let now = date(2026, 9, 27, 10, calendar: local)
            var pause = PauseModel(fileURL: file(), now: now)
            pause.select(.tomorrow, now: now)
            guard let deadline = pause.deadline(calendar: local) else { Issue.record("Missing deadline"); return }
            let parts = local.dateComponents([.year, .month, .day, .hour, .minute], from: deadline)
            #expect(parts.year == 2026 && parts.month == 9 && parts.day == 28)
            #expect(parts.hour == 9 && parts.minute == 0)
        }
        let newYork = calendar("America/New_York")
        let early = date(2026, 9, 27, 8, calendar: newYork)
        var earlyPause = PauseModel(fileURL: file(), now: early)
        earlyPause.select(.tomorrow, now: early)
        #expect(earlyPause.deadline(calendar: newYork) == date(2026, 9, 27, 9, calendar: newYork))
        for (month, day, expectedHours) in [(3, 7, 20.0), (10, 31, 22.0)] {
            let now = date(2026, month, day, 12, calendar: newYork)
            var pause = PauseModel(fileURL: file(), now: now)
            pause.select(.tomorrow, now: now)
            guard let deadline = pause.deadline(calendar: newYork) else { Issue.record("Missing deadline"); return }
            #expect(abs(deadline.timeIntervalSince(now) / 3600 - expectedHours) < 0.01)
            #expect(newYork.component(.hour, from: deadline) == 9)
        }
        let start = date(2026, 9, 27, 10, calendar: newYork)
        var traveling = PauseModel(fileURL: file(), now: start)
        traveling.select(.tomorrow, now: start)
        let tokyo = calendar("Asia/Tokyo")
        #expect(tokyo.component(.hour, from: traveling.deadline(calendar: tokyo)!) == 9)
        #expect(traveling.deadline(calendar: tokyo) != traveling.deadline(calendar: newYork))
    }

    @Test func reopeningAndEndingOneReasonPreservesOthers() {
        let url = file(), now = Date(timeIntervalSince1970: 1_000_000)
        var pause = PauseModel(fileURL: url, now: now)
        pause.select(.oneHour, now: now)
        pause.setOfficeHours(true)
        pause.setSleepOrLock(true)
        pause.setAutomaticActivity(true)
        #expect(pause.reasons.count == 4)
        pause.expire(now: now.addingTimeInterval(3600))
        #expect(pause.reasons == [.officeHours, .sleepOrLock, .automaticActivity])
        pause.setSleepOrLock(false)
        #expect(pause.reasons == [.officeHours, .automaticActivity])
        let reopened = PauseModel(fileURL: url, now: now.addingTimeInterval(3601))
        #expect(reopened.reasons.isEmpty)
        pause.setOfficeHours(false)
        #expect(pause.reasons == [.automaticActivity])
        pause.setAutomaticActivity(false)
        #expect(!pause.isPaused)
    }

    @Test func manualPauseSurvivesReopenAndLockAndBreakCycle() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settingsURL = directory.appendingPathComponent("settings.json")
        let model = AppContainer(settings: SettingsStore(url: settingsURL),
                                 statistics: StatisticsStore(url: directory.appendingPathComponent("stats.json")))
        model.pauseTracking(.untilResumed)
        model.tick(now: model.time, idle: 0, deliberateIdle: .infinity)
        model.suspendTracking()
        #expect(model.pause.reasons.contains(.manual) && model.pause.reasons.contains(.sleepOrLock))
        model.resumeManualPause()
        #expect(model.pause.reasons == [.sleepOrLock])
        model.pauseTracking(.untilResumed)
        model.resumeTracking(after: 1)
        #expect(model.pause.reasons.contains(.manual) && !model.pause.reasons.contains(.sleepOrLock))
        model.tick(now: model.time, idle: 0, deliberateIdle: .infinity)
        #expect(model.pause.reasons == [.manual])
        let completedBefore = model.breakEngine.shortBreaksSinceLong
        model.beginRest(.short, now: 0)
        model.breakEngine.advance(by: Double(model.config.shortRestSeconds))
        #expect(model.isPaused)
        #expect(model.breakEngine.shortBreaksSinceLong == completedBefore + 1)
        model.stop()
        let reopened = AppContainer(settings: SettingsStore(url: settingsURL),
                                    statistics: StatisticsStore(url: directory.appendingPathComponent("stats2.json")))
        #expect(reopened.isPaused)
        reopened.resumeManualPause()
        #expect(!reopened.isPaused)
        reopened.stop()
    }
}
