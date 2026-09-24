import SwiftUI

/// Keeps the draft separate from the live timer until editing is committed.
struct DurationField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    var step = 1
    @State private var draft = ""
    @State private var invalid = false
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(L(title))
                Spacer()
                TextField("", text: $draft)
                    .textFieldStyle(.roundedBorder).multilineTextAlignment(.trailing)
                    .frame(width: 64).monospacedDigit().focused($focused)
                    .accessibilityLabel(L(title)).accessibilityHint(L(unit))
                    .onSubmit { commit() }
                    .onExitCommand { draft = String(value); invalid = false; focused = false }
                Text(L(unit)).foregroundStyle(.secondary).frame(minWidth: 25, alignment: .leading)
                Stepper(L(title), value: Binding(get: { value }, set: { next in
                    value = next; draft = String(next); invalid = false
                }), in: range, step: step).labelsHidden().fixedSize()
            }
            if invalid {
                Text(L("Enter a whole number from") + " \(range.lowerBound)–\(range.upperBound).")
                    .font(.caption).foregroundStyle(.red)
            }
        }
        .onAppear { draft = String(value) }
        .onChange(of: value) { _, new in if !focused { draft = String(new); invalid = false } }
        .onChange(of: focused) { _, active in if !active { commit() } }
    }
    private func commit() {
        guard let parsed = DurationInput.parse(draft, within: range) else { invalid = true; return }
        value = parsed; draft = String(parsed); invalid = false
    }
}
