import Foundation
import Testing
@testable import Offscreen

@Suite struct CountdownCadenceTests {
    private func withModel(_ body: (AppContainer) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settings = SettingsStore(url: directory.appendingPathComponent("settings.json"))
        settings.update {
            $0.videoEnabled = false; $0.cameraSuppression = false; $0.focusSuppression = false
            $0.startTone = .none; $0.pauseTone = .none; $0.resumeTone = .none
            $0.breakTone = .none; $0.endTone = .none; $0.reminderTone = .none
        }
        let model = AppContainer(settings: settings,
            statistics: StatisticsStore(url: directory.appendingPathComponent("statistics.json")),
            quietSignalReader: { _ in QuietSignalSnapshot() })
        defer { model.stop() }
        try body(model)
    }

    @Test func fixedCadenceReproducesTheReportedRepeatThenDoubleStep() throws {
        try withModel { model in
            var shown: [String] = []
            for now in [0.07, 1.06, 2.08, 3.06, 4.08] {
                model.tick(now: now, idle: 0, deliberateIdle: .infinity)
                shown.append(model.nextReadout.clock)
            }
            #expect(shown == ["20:00", "20:00", "19:58", "19:58", "19:56"])
            #expect(abs(model.breakEngine.workAccrued - 4.01) < 1e-8)
        }
    }

    @Test func rephasingShowsEverySecondWithChangingPermittedTimerDelays() throws {
        for phase in [0.0, 0.07, 0.49, 0.99] {
            try withModel { model in
                var now = phase
                model.tick(now: now, idle: 0, deliberateIdle: .infinity)
                // A fractional work position also represents returning from pause.
                model.breakEngine.advance(by: phase)
                var previous = Int(ceil(model.nextReadout.seconds))
                let lateness = [0.0, 0.199, 0.001, 0.2, 0.03, 0.12]
                for index in 0..<120 {
                    now += model.nextTickDelay() + lateness[index % lateness.count]
                    model.tick(now: now, idle: 0, deliberateIdle: .infinity)
                    let shown = Int(ceil(model.nextReadout.seconds))
                    #expect(previous - shown == 1)
                    previous = shown
                }
                #expect(abs(model.breakEngine.workAccrued - now) < 1e-8)
                // Rephase, rather than adding a continuously faster poll.
                #expect(now - phase >= 119 && now - phase <= 121)
            }
        }
    }

    @Test func shortAndLongRestsShowEachSecondAndCompleteOnlyWhenDue() throws {
        for kind in [MolaKind.short, .long] {
            try withModel { model in
                let start = 0.37
                var now = start
                model.tick(now: now, idle: 0, deliberateIdle: .infinity)
                model.beginRest(kind, now: now)
                let duration = model.breakEngine.breakDuration
                var previous = Int(ceil(duration))
                var count = 0
                while model.activeRest != nil && count < Int(duration) + 2 {
                    now += model.nextTickDelay() + (count.isMultiple(of: 2) ? 0.199 : 0)
                    model.tick(now: now, idle: now - start, deliberateIdle: .infinity)
                    if model.activeRest != nil {
                        let shown = Int(ceil(model.nextReadout.seconds))
                        #expect(previous - shown == 1)
                        previous = shown
                        #expect(now - start < duration)
                    } else {
                        #expect(previous == 1)
                        #expect(now - start >= duration && now - start < duration + 0.3)
                    }
                    count += 1
                }
                #expect(model.activeRest == nil)
                #expect(model.breakEngine.shortBreaksSinceLong == (kind == .short ? 1 : 0))
            }
        }
    }

    @Test func manualPauseAndResumeKeepWorkFrozenThenRephase() throws {
        try withModel { model in
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.tick(now: 0.43, idle: 0, deliberateIdle: .infinity)
            model.pauseTracking(.untilResumed)
            let saved = model.breakEngine.workAccrued
            for now in [1.43, 2.43, 3.43] {
                model.tick(now: now, idle: 0, deliberateIdle: .infinity)
                #expect(model.nextTickDelay() == 1)
                #expect(model.breakEngine.workAccrued == saved)
            }
            model.resumeManualPause()
            model.tick(now: 100, idle: 0, deliberateIdle: .infinity)
            let remaining = model.nextReadout.seconds
            let delay = model.nextTickDelay()
            model.tick(now: 100 + delay + 0.19, idle: 0, deliberateIdle: .infinity)
            #expect(Int(ceil(remaining)) - Int(ceil(model.nextReadout.seconds)) == 1)
        }
    }

    @Test func automaticIdlePauseDoesNotRunAnAlignmentLoop() throws {
        try withModel { model in
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.tick(now: 1.23, idle: 0, deliberateIdle: .infinity)
            model.tick(now: 200, idle: 200, deliberateIdle: .infinity)
            let saved = model.breakEngine.workAccrued
            #expect(model.activity == .away && model.nextTickDelay() == 1)
            model.tick(now: 201, idle: 201, deliberateIdle: .infinity)
            #expect(model.breakEngine.workAccrued == saved)
            model.tick(now: 202, idle: 0, deliberateIdle: .infinity)
            let remaining = model.nextReadout.seconds
            let delay = model.nextTickDelay()
            model.tick(now: 202 + delay + 0.19, idle: 0, deliberateIdle: .infinity)
            #expect(Int(ceil(remaining)) - Int(ceil(model.nextReadout.seconds)) == 1)
        }
    }

    @Test func sleepGapIsNotCountedAndWakeUsesAFreshSample() throws {
        try withModel { model in
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.tick(now: 1.37, idle: 0, deliberateIdle: .infinity)
            let saved = model.breakEngine.workAccrued
            model.suspendTracking()
            #expect(model.nextTickDelay() == 1)
            model.tick(now: 500, idle: 0, deliberateIdle: .infinity)
            #expect(model.breakEngine.workAccrued == saved)
            model.resumeTracking(after: 5)
            model.tick(now: 501, idle: 0, deliberateIdle: .infinity)
            #expect(model.breakEngine.workAccrued == saved)
            let remaining = model.nextReadout.seconds
            let delay = model.nextTickDelay()
            model.tick(now: 501 + delay + 0.19, idle: 0, deliberateIdle: .infinity)
            #expect(Int(ceil(remaining)) - Int(ceil(model.nextReadout.seconds)) == 1)
        }
    }

    @Test func longStallsCatchUpHonestlyInsteadOfFakingSingleSteps() throws {
        try withModel { model in
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.tick(now: 2.6, idle: 0, deliberateIdle: .infinity)
            #expect(model.nextReadout.clock == "19:58")
            #expect(abs(model.breakEngine.workAccrued - 2.6) < 1e-8)
            model.tick(now: 20, idle: 0, deliberateIdle: .infinity)
            #expect(abs(model.breakEngine.workAccrued - 2.6) < 1e-8)
        }
    }

    @Test func deferredReminderUsesItsOwnCountdownBoundary() throws {
        try withModel { model in
            model.tick(now: 0, idle: 0, deliberateIdle: .infinity)
            model.breakEngine.advance(by: 1200.37)
            model.tick(now: 0.01, idle: 0, deliberateIdle: .infinity)
            model.snoozeReminder()
            let start = model.breakEngine.workAccrued
            let delay = model.nextTickDelay()
            model.tick(now: 0.01 + delay + 0.19, idle: 0, deliberateIdle: .infinity)
            #expect(model.nextReadout.deferred)
            #expect(model.nextReadout.clock == "4:59")
            #expect(model.breakEngine.explicitDeferrals == 1)
            #expect(abs(model.breakEngine.workAccrued - start - delay - 0.19) < 1e-8)
        }
    }

    @Test func schedulingIsBoundedAndAccountsForWorkDoneBeforeRefreshing() {
        for remaining in [20.0, 19.99, 19.01, 0.1, 10_800.0] {
            let first = CountdownCadence.delay(remaining: remaining, counting: true)
            let processed = CountdownCadence.delay(remaining: remaining, counting: true, sampleAge: 0.01)
            #expect(first >= 0.05 && first <= 1.05)
            #expect(abs(processed - max(0.05, first - 0.01)) < 1e-8)
            #expect(CountdownCadence.delay(remaining: remaining, counting: false) == 1)
            #expect(CountdownCadence.delay(remaining: remaining, counting: true, sampleAge: 5) == 0.05)
        }
        for remaining in [0, -1, Double.nan, .infinity] {
            #expect(CountdownCadence.delay(remaining: remaining, counting: true) == 1)
        }
        for age in [-1, Double.nan, .infinity] {
            #expect(CountdownCadence.delay(remaining: 10.5, counting: true, sampleAge: age) == 1)
        }
    }
}
