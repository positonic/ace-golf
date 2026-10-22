import SwiftUI

/// Licence, attribution and credits. ODbL requires the OpenStreetMap attribution to be visible in the app.
struct AboutView: View {
    var onNewRound: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var confirmNewRound = false

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                if onNewRound != nil {
                    Section("Round") {
                        Button("Start a new round", role: .destructive) { confirmNewRound = true }
                            .confirmationDialog("Clear the scorecard and start a new round?", isPresented: $confirmNewRound, titleVisibility: .visible) {
                                Button("Start new round", role: .destructive) { onNewRound?(); dismiss() }
                            }
                        Text("The current round stays saved as a file in the app's Documents folder.")
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    LabeledContent("Version", value: version)
                    LabeledContent("Licence", value: "AGPL-3.0 with App Store exception")
                    Link("Source code on GitHub", destination: URL(string: "https://github.com/positonic/ace-golf")!)
                } header: {
                    Text("Ace Golf")
                }
                Section("Course data") {
                    Text("Course data © OpenStreetMap contributors, available under the Open Database License (ODbL).")
                    Link("openstreetmap.org/copyright", destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                    Text("Found an error on a course? Fix it on OpenStreetMap and every open golf app benefits.")
                        .foregroundStyle(.secondary)
                }
                Section("Satellite imagery") {
                    Text("Provided by Apple Maps under Apple's terms.")
                }
                Section("Credits") {
                    Text("Modelled on Ace, an open-source browser golf app by Bruce Lucas. Ace Golf is a clean reimplementation in Swift.")
                    Link("github.com/bdlucas1/ace", destination: URL(string: "https://github.com/bdlucas1/ace")!)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

#Preview { AboutView() }
