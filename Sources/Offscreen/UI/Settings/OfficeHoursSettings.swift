import SwiftUI

struct OfficeHoursSettings: View {
    let model: AppContainer

    var body: some View {
        Section(L("Office Hours")) {
            Toggle(L("Use Office Hours"), isOn: model.settings.binding(\.officeHours.enabled))
            if model.config.officeHours.enabled {
                ForEach(OfficeHours.orderedDays, id: \.self) { day in
                    Toggle(OfficeHours.dayTitle(day), isOn: Binding(
                        get: { model.config.officeHours.weekdays.contains(day) },
                        set: { selected in model.settings.update {
                            if selected { $0.officeHours.weekdays.insert(day) }
                            else { $0.officeHours.weekdays.remove(day) }
                        } }
                    ))
                }
                timePicker("Work starts", key: \.startMinute)
                timePicker("Work ends", key: \.endMinute)
                Text(model.officeHoursText).font(.caption)
                if let next = model.nextOfficeStartText { Text(next).font(.caption) }
                Text(L("Overnight shifts belong to the day they start. Equal start and end times mean 24 hours."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(L("Uses your current local time zone. Outside these hours, work time stops accumulating; manual breaks stay available."))
                .font(.caption).foregroundStyle(.secondary)
            Text(L("Until tomorrow uses the next selected work start when Office Hours is on, or the next local 09:00 when off. Other pause reasons stay active."))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func timePicker(_ title: String, key: WritableKeyPath<OfficeHours, Int>) -> some View {
        // A fixed, non-DST reference date keeps every hour/minute editable even
        // on a day when the system clock skips an hour.
        let zone = TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let reference = Date(timeIntervalSince1970: 0)
        return DatePicker(L(title), selection: Binding(
            get: { reference.addingTimeInterval(Double(model.config.officeHours[keyPath: key] * 60)) },
            set: { value in
                let parts = calendar.dateComponents([.hour, .minute], from: value)
                model.settings.update { $0.officeHours[keyPath: key] = (parts.hour ?? 0) * 60 + (parts.minute ?? 0) }
            }
        ), displayedComponents: .hourAndMinute)
        .environment(\.timeZone, zone)
        .environment(\.calendar, calendar)
        .environment(\.locale, Locale(identifier: Localization.shared.code))
        .accessibilityLabel(L(title))
        .accessibilityValue(Text(String(format: "%02d:%02d", model.config.officeHours[keyPath: key] / 60,
                                       model.config.officeHours[keyPath: key] % 60)))
    }
}
