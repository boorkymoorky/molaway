import SwiftUI

struct PauseControls: View {
    let model: AppContainer

    var body: some View {
        if model.isPaused {
            Button(L("Resume manual pause")) { model.resumeManualPause() }
        } else {
            Menu {
                ForEach(PauseOption.allCases, id: \.self) { option in
                    Button(option.title) { model.pauseTracking(option) }
                }
            } label: {
                Label(L("Pause tracking"), systemImage: "pause.circle")
            }
        }
    }
}
