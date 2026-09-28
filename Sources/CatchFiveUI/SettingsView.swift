import CatchFive
import SwiftUI

struct SettingsView: View {
    @Binding var settings: Settings
    @Environment(\.dismiss) private var dismiss
    @State private var nameDraft = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Computer strength", selection: $settings.difficulty) {
                        Text("Easy").tag(Difficulty.easy)
                        Text("Standard").tag(Difficulty.standard)
                    }.pickerStyle(.segmented)
                } header: { Text("Difficulty") } footer: {
                    Text("Easy players use the original strategy and lose about two matches in three to Standard. Hints always use Standard.")
                }
                Section("You") {
                    // A draft, so spaces and clearing work while typing; each non-blank edit is committed.
                    TextField("Your name", text: $nameDraft)
                        .onAppear { nameDraft = settings.playerName ?? settings.seatNames[0] }
                        .onChange(of: nameDraft) { _, new in settings.setPlayerName(new) }
                    HStack(spacing: 16) {
                        ForEach(Array(Cast.playerChoices.enumerated()), id: \.offset) { index, choice in
                            Button { settings.playerPortrait = choice } label: {
                                PortraitView(portrait: choice, size: 44)
                                    .opacity(settings.playerPortrait == choice ? 1 : Theme.Card.dimmedOpacity)
                                    .overlay(Circle().stroke(Color.suitRed, lineWidth: settings.playerPortrait == choice ? 3 : 0))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Face \(index + 1)")
                            .accessibilityAddTraits(settings.playerPortrait == choice ? .isSelected : [])
                        }
                    }.frame(maxWidth: .infinity)
                }
                Section("Opponents") {
                    ForEach(1..<4, id: \.self) { seat in
                        HStack(spacing: 12) {
                            if let character = Cast.opponent(at: seat) { PortraitView(portrait: character.portrait, size: 28) }
                            TextField(Settings.defaultSeatNames[seat], text: Binding(
                                get: { settings.seatNames[seat] },
                                set: { settings.seatNames[seat] = $0.trimmingCharacters(in: .whitespaces).isEmpty ? Settings.defaultSeatNames[seat] : $0 }))
                        }
                    }
                }
                Section {
                    Toggle("Haptics on every hand", isOn: $settings.haptics)
                }
            }
            .scrollContentBackground(.hidden)
            .background(WoodGrainView().ignoresSafeArea())
            .tint(Color.suitRed)
            .navigationTitle("Settings")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
