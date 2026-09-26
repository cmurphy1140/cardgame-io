import CatchFive
import SwiftUI

/// Every play of the finished hand next to what the standard strategy would have done.
struct ReviewView: View {
    let review: HandReview
    let names: [String]
    let difficulty: Difficulty
    /// Words one reviewed play; shared with tap-to-explain so the two never differ.
    let describe: (PlayReview) -> String
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                let (agreed, total) = review.agreement(forSeat: 0)
                Section {
                    Text("You played the strategy's card \(agreed) of \(total) times. Rows marked with a branch show where the standard strategy would have played differently\(difficulty == .easy ? "; the computers are on Easy, so their rows compare them to Standard too" : ""). Standard's choice is a recommendation, not proof that another legal play was wrong.")
                        .font(.footnote)
                }
                ForEach(review.tricks, id: \.number) { trick in
                    Section("Trick \(trick.number) · \(names[trick.winner]) took it") {
                        ForEach(trick.plays, id: \.play.card) { row($0) }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(WoodGrainView().ignoresSafeArea())
            .navigationTitle("Hand review")
            .toolbar { Button("Done", action: onDismiss) }
        }
    }

    @ViewBuilder private func row(_ review: PlayReview) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(names[review.play.seat]).font(.subheadline.weight(.semibold))
                Spacer()
                Text(review.play.card.name).font(.subheadline)
                Image(systemName: review.agreed ? "checkmark" : "arrow.triangle.branch")
                    .foregroundStyle(review.agreed ? Color.secondary : Color.primary)
            }
            if !review.agreed {
                Text(describe(review)).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Shown if a review could not be built, so the sheet always has content and a Done button.
struct ReviewUnavailableView: View {
    let onDismiss: () -> Void
    var body: some View {
        NavigationStack {
            Text("Nothing to review yet.").foregroundStyle(.secondary)
                .navigationTitle("Hand review")
                .toolbar { Button("Done", action: onDismiss) }
        }
    }
}

/// Every hand of the match so far.
struct ScoreboardView: View {
    let history: [HandSummary]
    let names: [String]
    let onDismiss: () -> Void

    private var scores: [Int] { history.last?.scores ?? [0, 0] }

    var body: some View {
        NavigationStack {
            ZStack {
                WoodGrainView().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 3) {
                            Text("SCORE").font(.system(.largeTitle, design: .serif).weight(.bold))
                            Text("FIRST TO 25 POINTS").font(.caption.monospaced().weight(.semibold)).tracking(2)
                        }
                        .foregroundStyle(.ivory)

                        VStack(spacing: 18) {
                            HStack {
                                team("US", names: "\(names[0]) & \(names[2])", symbol: "♥", score: scores[0], red: true)
                                Divider().frame(height: 74)
                                team("THEM", names: "\(names[1]) & \(names[3])", symbol: "♠", score: scores[1], red: false)
                            }
                            Divider()
                            track("US", score: scores[0])
                            track("THEM", score: scores[1])
                        }
                        .padding(18)
                        .background(.ivory, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Theme.Wood.header.opacity(0.45), lineWidth: 1.5))
                        .foregroundStyle(.black)

                        handHistory
                    }
                    .padding(20)
                }
            }
            .toolbar { Button("Done", action: onDismiss).tint(.ivory) }
        }
        .preferredColorScheme(.dark)
    }

    private func team(_ label: String, names: String, symbol: String, score: Int, red: Bool) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 5) {
                Text(symbol).foregroundStyle(red ? Color.suitRed : .black)
                Text(label).font(.caption.monospaced().weight(.bold)).tracking(1)
            }
            Text(names).font(.caption2).opacity(0.65).lineLimit(1).minimumScaleFactor(0.7)
            Text(score, format: .number)
                .font(.system(size: 42, weight: .bold, design: .serif))
                .foregroundStyle(Color.suitRed)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func track(_ label: String, score: Int) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("\(label) · \(score)").font(.caption.monospaced().weight(.bold)).tracking(1)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                ForEach(1...25, id: \.self) { point in
                    Text("\(point)")
                        .font(.caption2.monospacedDigit().weight(.semibold))
                        .foregroundStyle(point <= score ? Color.ivory : .black.opacity(0.6))
                        .frame(maxWidth: .infinity, minHeight: 30)
                        .background(point <= score ? Color.suitRed : Color.clear, in: Circle())
                        .overlay(Circle().stroke(.black.opacity(0.2), lineWidth: point <= score ? 0 : 1))
                }
            }
        }
    }

    @ViewBuilder private var handHistory: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HANDS").font(.caption.monospaced().weight(.bold)).tracking(2).foregroundStyle(.ivory)
            if history.isEmpty {
                Text("No hands scored yet.").foregroundStyle(.ivory.opacity(0.75))
            } else {
                ForEach(history, id: \.number) { hand in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hand \(hand.number)").font(.subheadline.weight(.semibold))
                            Text("\(names[hand.bidder]) bid \(hand.isNineAndOut ? "9 and out" : String(hand.bid)), \(hand.contractMade ? "made" : "set")")
                                .font(.footnote).opacity(0.65)
                        }
                        Spacer()
                        Text("\(hand.scores[0]) – \(hand.scores[1])").font(.headline.monospacedDigit())
                    }
                    .padding(12)
                    .background(.ivory, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.black)
                }
            }
        }
    }
}

/// Totals across recorded matches, newest first.
struct StatisticsView: View {
    let stats: Statistics
    let records: [MatchRecord]
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("All matches") {
                    line("Matches", "\(stats.matches)")
                    line("Won", stats.matches == 0 ? "–" : "\(stats.wins) (\(percent(Double(stats.wins) / Double(stats.matches))))")
                    line("Average margin", stats.matches == 0 ? "–" : String(format: "%+.1f", stats.averageMargin))
                    line("Contracts made", stats.contractRate.map(percent) ?? "–")
                    line("Played the strategy's card", stats.agreementRate.map(percent) ?? "–")
                }
                Section("Recent") {
                    if records.isEmpty { Text("Finish a match to see it here.").foregroundStyle(.secondary) }
                    ForEach(records.reversed()) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.humanWon ? "Won" : "Lost").font(.subheadline.weight(.semibold))
                                Text("\(record.date.formatted(date: .abbreviated, time: .shortened)) · \(record.hands) hands · \(record.difficulty.rawValue)")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(record.scores[0]) – \(record.scores[1])").font(.headline.monospacedDigit())
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(WoodGrainView().ignoresSafeArea())
            .navigationTitle("Statistics")
            .toolbar { Button("Done", action: onDismiss) }
        }
    }

    private func line(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).foregroundStyle(.secondary) }
    }
    private func percent(_ value: Double) -> String { "\(Int((value * 100).rounded()))%" }
}
