import Foundation
import Testing
@testable import Offscreen

@Suite struct OfficeHoursTests {
    private func calendar(_ zone: String = "UTC") -> Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: zone)!
        return value
    }
    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
    private func schedule(_ days: Set<Int> = [2, 3, 4, 5, 6], _ start: Int = 540, _ end: Int = 1020) -> OfficeHours {
        OfficeHours(enabled: true, weekdays: days, startMinute: start, endMinute: end)
    }
    private final class WallClock {
        var now: Date
        var calendar: Calendar
        init(_ now: Date, _ calendar: Calendar) { self.now = now; self.calendar = calendar }
    }
    private func withModel(_ hours: OfficeHours, at now: String = "2026-09-28T08:59:59Z",
                           _ body: (AppContainer, WallClock, URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settings = SettingsStore(url: directory.appendingPathComponent("settings.json"))
        settings.update { $0.officeHours = hours; $0.videoEnabled = false; $0.shortBreaksBeforeLong = 3 }
        let clock = WallClock(date(now), calendar())
        let model = AppContainer(settings: settings, statistics: StatisticsStore(url: directory.appendingPathComponent("stats.json")),
                                 wallClock: { clock.now }, localCalendar: { clock.calendar })
        defer { model.stop() }
        try body(model, clock, directory)
    }
    private func tick(_ model: AppContainer, _ clock: WallClock, _ uptime: Double, _ wall: String, idle: Double = 0) {
        clock.now = date(wall)
        model.tick(now: uptime, idle: idle, deliberateIdle: .infinity)
    }

    @Test func weekdayStartInclusiveEndExclusiveAndWeekend() {
        let hours = schedule(), cal = calendar()
        #expect(!hours.isOpen(at: date("2026-09-28T08:59:59Z"), calendar: cal))
        #expect(hours.isOpen(at: date("2026-09-28T09:00:00Z"), calendar: cal))
        #expect(hours.isOpen(at: date("2026-09-28T16:59:59Z"), calendar: cal))
        #expect(!hours.isOpen(at: date("2026-09-28T17:00:00Z"), calendar: cal))
        #expect(!hours.isOpen(at: date("2026-10-03T12:00:00Z"), calendar: cal))
        #expect(hours.nextStart(after: date("2026-10-02T17:00:00Z"), calendar: cal) == date("2026-10-05T09:00:00Z"))
        #expect(hours.nextStart(after: date("2026-09-28T09:00:00Z"), calendar: cal) == date("2026-09-29T09:00:00Z"))
    }

    @Test func overnightBelongsToSundayAcrossWeekAndMonthBoundary() {
        let hours = schedule([1], 22 * 60, 6 * 60), cal = calendar()
        #expect(!hours.isOpen(at: date("2026-05-31T05:00:00Z"), calendar: cal))
        #expect(hours.isOpen(at: date("2026-05-31T22:00:00Z"), calendar: cal))
        #expect(hours.isOpen(at: date("2026-06-01T05:59:59Z"), calendar: cal))
        #expect(!hours.isOpen(at: date("2026-06-01T06:00:00Z"), calendar: cal))
        #expect(!hours.isOpen(at: date("2026-06-01T22:00:00Z"), calendar: cal))
        #expect(hours.nextStart(after: date("2026-06-01T02:00:00Z"), calendar: cal) == date("2026-06-07T22:00:00Z"))
    }

    @Test func equalTimesAreFullDayAndEmptyDaysStayClosed() {
        let hours = schedule([2], 540, 540), cal = calendar()
        #expect(hours.isOpen(at: date("2026-09-29T08:59:59Z"), calendar: cal))
        #expect(!hours.isOpen(at: date("2026-09-29T09:00:00Z"), calendar: cal))
        let empty = schedule([])
        #expect(!empty.isOpen(at: date("2026-09-28T10:00:00Z"), calendar: cal))
        #expect(empty.nextStart(after: date("2026-09-28T10:00:00Z"), calendar: cal) == nil)
        #expect(OfficeHours().isOpen(at: date("2026-09-27T23:00:00Z"), calendar: cal))
    }

    @Test func springGapUsesNextValidTimeAndOvernightUsesCalendarDays() throws {
        let cal = calendar("America/New_York")
        let hours = schedule([1], 150, 240)
        #expect(hours.nextStart(after: date("2026-03-08T06:00:00Z"), calendar: cal) == date("2026-03-08T07:00:00Z"))
        #expect(!hours.isOpen(at: date("2026-03-08T06:59:59Z"), calendar: cal))
        #expect(hours.isOpen(at: date("2026-03-08T07:00:00Z"), calendar: cal))
        #expect(!hours.isOpen(at: date("2026-03-08T08:00:00Z"), calendar: cal))
        let overnight = schedule([7], 22 * 60, 6 * 60)
        let interval = try #require(overnight.interval(containing: date("2026-03-08T07:00:00Z"), calendar: cal))
        #expect(interval.duration == 25_200)
        let missingEnd = schedule([1], 60, 150)
        #expect(!missingEnd.isOpen(at: date("2026-03-08T07:00:00Z"), calendar: cal))
    }

    @Test func fallRepeatedHourUsesFirstStartAndLastEnd() throws {
        let cal = calendar("America/New_York"), hours = schedule([1], 90, 105)
        #expect(hours.nextStart(after: date("2026-11-01T04:00:00Z"), calendar: cal) == date("2026-11-01T05:30:00Z"))
        #expect(hours.isOpen(at: date("2026-11-01T05:30:00Z"), calendar: cal))
        #expect(hours.isOpen(at: date("2026-11-01T06:15:00Z"), calendar: cal))
        #expect(!hours.isOpen(at: date("2026-11-01T06:45:00Z"), calendar: cal))
        let overnight = schedule([7], 22 * 60, 6 * 60)
        let interval = try #require(overnight.interval(containing: date("2026-11-01T06:00:00Z"), calendar: cal))
        #expect(interval.duration == 32_400)
    }

    @Test func localZoneChangesReevaluateDaysAndHours() {
        let now = date("2026-09-28T13:00:00Z"), hours = schedule([2])
        #expect(hours.isOpen(at: now, calendar: calendar("America/New_York")))
        #expect(!hours.isOpen(at: now, calendar: calendar("Asia/Tokyo")))
        #expect(hours.nextStart(after: now, calendar: calendar("Asia/Tokyo")) == date("2026-10-05T00:00:00Z"))
    }

    @Test func settingsMigrationValidationAndRoundTrip() throws {
        #expect(try !SettingsCodec.decode(Data("{}".utf8)).officeHours.enabled)
        var settings = AppSettings()
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(settings)) as? [String: Any])
        object.removeValue(forKey: "officeHours")
        #expect(try SettingsCodec.decode(JSONSerialization.data(withJSONObject: object)).officeHours == OfficeHours())
        settings.officeHours = schedule([0, 2, 8], Int.min, Int.max)
        settings.validate()
        #expect(settings.officeHours.weekdays == [2])
        #expect(settings.officeHours.startMinute == 0 && settings.officeHours.endMinute == 1439)
        #expect(try SettingsCodec.decode(SettingsCodec.export(settings), strict: true).officeHours == settings.officeHours)
    }

    @Test func tomorrowPersistsPastNineUntilNextSelectedStart() throws {
        try withModel(schedule([2], 22 * 60, 6 * 60), at: "2026-09-27T12:00:00Z") { model, clock, directory in
            model.pauseTracking(.tomorrow)
            #expect(model.pauseUntil == date("2026-09-28T22:00:00Z"))
            model.settings.flush()
            clock.now = date("2026-09-28T12:00:00Z")
            let reopened = AppContainer(settings: SettingsStore(url: directory.appendingPathComponent("settings.json")),
                statistics: StatisticsStore(url: directory.appendingPathComponent("stats2.json")),
                wallClock: { clock.now }, localCalendar: { clock.calendar })
            defer { reopened.stop() }
            #expect(reopened.pause.reasons == [.manual, .officeHours])
            tick(reopened, clock, 0, "2026-09-28T22:00:00Z")
            #expect(!reopened.pause.isPaused)
        }
    }

    @Test func tomorrowFollowsEditsEmptyDaysDisablingAndTravel() throws {
        try withModel(schedule(), at: "2026-09-28T10:00:00Z") { model, clock, _ in
            model.pauseTracking(.tomorrow)
            model.settings.update { $0.officeHours.weekdays = [] }
            #expect(model.pauseUntil == nil && model.isPaused && model.outsideOfficeHours)
            model.settings.update { $0.officeHours.weekdays = [4]; $0.officeHours.startMinute = 600 }
            #expect(model.pauseUntil == date("2026-09-30T10:00:00Z"))
            clock.calendar = calendar("Asia/Tokyo")
            #expect(model.pauseUntil == date("2026-09-30T01:00:00Z"))
            model.settings.update { $0.officeHours.enabled = false }
            #expect(model.pauseUntil == date("2026-09-29T00:00:00Z"))
            #expect(model.isPaused && !model.outsideOfficeHours)
        }
    }

    @Test func openingHoursDoesNotClearManualLockOrAutomaticPause() throws {
        try withModel(schedule()) { model, clock, _ in
            model.pauseTracking(.untilResumed)
            tick(model, clock, 0, "2026-09-28T08:59:59Z", idle: 200)
            model.suspendTracking()
            #expect(model.pause.reasons == [.manual, .officeHours, .automaticActivity, .sleepOrLock])
            tick(model, clock, 1, "2026-09-28T09:00:00Z", idle: 201)
            #expect(model.pause.reasons == [.manual, .automaticActivity, .sleepOrLock])
            model.resumeTracking(after: 1)
            tick(model, clock, 2, "2026-09-28T09:00:01Z", idle: 202)
            #expect(model.pause.reasons == [.manual, .automaticActivity])
            model.resumeManualPause()
            tick(model, clock, 3, "2026-09-28T09:00:02Z", idle: 203)
            #expect(model.pause.reasons == [.automaticActivity])
            #expect(model.breakEngine.workAccrued == 0)
        }
    }

    @Test func closedHoursFreezeDebtSnoozeAndCadenceWithoutAlerts() throws {
        try withModel(schedule(), at: "2026-09-28T16:59:59Z") { model, clock, _ in
            model.breakEngine.advance(by: 1200)
            model.reminderKinds = [.short]
            model.snoozeReminder()
            var alerts = 0
            model.showReminder = { alerts += 1 }
            tick(model, clock, 0, "2026-09-28T16:59:59Z")
            tick(model, clock, 1, "2026-09-28T17:00:00Z")
            for second in 2...60 {
                clock.now = date("2026-09-28T17:00:00Z").addingTimeInterval(Double(second))
                model.tick(now: Double(second), idle: 0, deliberateIdle: .infinity)
            }
            #expect(model.breakEngine.workAccrued == 1200)
            #expect(model.breakEngine.timeUntilReminder == 300)
            #expect(model.breakEngine.shortBreaksSinceLong == 0 && alerts == 0)
            tick(model, clock, 61, "2026-09-29T09:00:00Z")
            tick(model, clock, 62, "2026-09-29T09:00:01Z")
            #expect(model.breakEngine.workAccrued == 1201)
            #expect(model.breakEngine.timeUntilReminder == 299)
        }
    }

    @Test func offHoursIdleAndSleepCannotInventCompletedBreaks() throws {
        try withModel(schedule(), at: "2026-09-28T18:00:00Z") { model, clock, _ in
            model.breakEngine.advance(by: 600)
            tick(model, clock, 0, "2026-09-28T18:00:00Z", idle: 500)
            model.suspendTracking()
            clock.now = date("2026-09-29T09:00:00Z")
            model.resumeTracking(after: 15 * 3600)
            tick(model, clock, 15 * 3600, "2026-09-29T09:00:00Z", idle: 15 * 3600)
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
            #expect(model.breakEngine.workAccrued == 600)
            #expect(model.pause.reasons == [.automaticActivity])
            tick(model, clock, 15 * 3600 + 20, "2026-09-29T09:00:20Z", idle: 15 * 3600 + 20)
            #expect(model.breakEngine.shortBreaksSinceLong == 1)
            tick(model, clock, 15 * 3600 + 21, "2026-09-29T09:00:21Z", idle: 15 * 3600 + 21)
            #expect(model.breakEngine.shortBreaksSinceLong == 1)
        }
    }

    @Test func manualBreaksRemainAvailableOutsideHoursAndKeepPauseReasons() throws {
        try withModel(schedule(), at: "2026-09-28T18:00:00Z") { model, clock, _ in
            model.pauseTracking(.untilResumed)
            model.beginRest(.short, now: 0)
            #expect(model.activeRest == .short)
            #expect(model.statusText == L("Enjoy your break"))
            for second in 1...20 {
                clock.now = date("2026-09-28T18:00:00Z").addingTimeInterval(Double(second))
                model.tick(now: Double(second), idle: Double(second), deliberateIdle: .infinity)
            }
            // The first synthetic tick establishes its monotonic baseline.
            model.tick(now: 21, idle: 21, deliberateIdle: .infinity)
            #expect(model.activeRest == nil)
            #expect(model.breakEngine.shortBreaksSinceLong == 1)
            #expect(model.pause.reasons == [.manual, .officeHours])
            model.beginRest(.long, now: 22)
            model.breakEngine.advance(by: Double(model.config.longRestMinutes * 60))
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
            #expect(model.pause.reasons == [.manual, .officeHours])
        }
    }

    @Test func closingHoursKeepsActiveRestAndEarlyEndDoesNotCount() throws {
        try withModel(schedule(), at: "2026-09-28T16:59:59Z") { model, clock, _ in
            tick(model, clock, 0, "2026-09-28T16:59:59Z")
            model.beginRest(.short, now: 0)
            tick(model, clock, 1, "2026-09-28T17:00:00Z", idle: 1)
            #expect(model.activeRest == .short && model.outsideOfficeHours)
            #expect(model.breakEngine.breakElapsed == 1)
            model.cancelRest()
            #expect(model.breakEngine.shortBreaksSinceLong == 0)
            tick(model, clock, 2, "2026-09-28T17:00:01Z")
            #expect(model.activity == .paused)
        }
    }

    @Test func settingsChangesAndTimeZoneChangesApplyWithoutRestart() throws {
        try withModel(schedule(), at: "2026-09-28T10:00:00Z") { model, clock, _ in
            #expect(!model.outsideOfficeHours)
            model.settings.update { $0.officeHours.startMinute = 660 }
            #expect(model.outsideOfficeHours)
            model.settings.update { $0.officeHours.enabled = false }
            #expect(!model.outsideOfficeHours)
            model.settings.update { $0.officeHours.enabled = true }
            clock.calendar = calendar("Europe/Istanbul")
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            #expect(!model.outsideOfficeHours)
            clock.calendar = calendar("Asia/Tokyo")
            model.tick(now: 1, idle: 0, deliberateIdle: .infinity)
            #expect(model.outsideOfficeHours && !model.canPresent)
        }
    }
}
