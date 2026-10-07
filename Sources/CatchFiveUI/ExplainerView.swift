import Foundation
import SwiftUI

/// The engineering explainer, read natively from the docs themselves. `docs/learning-path.md` is the
/// contents page: its reading-order table names the chapters and its glossary the Swift vocabulary.
/// Each chapter is that doc's full Markdown, bundled under `Explainer/docs`, with every Mermaid
/// diagram rendered to `Explainer/diagrams/<file>-<n>.png` by `scripts/export-docs.py --app`.
public enum ExplainerLibrary {
    public static let folder = "Explainer"

    struct Chapter: Equatable, Hashable, Identifiable {
        let number: Int
        /// The doc's file name without `.md`, e.g. "architecture".
        let file: String
        /// "What you will understand afterwards", from the learning path's table.
        let summary: String
        var id: String { file }
    }

    struct GlossaryEntry: Equatable {
        let term: String
        let meaning: String
        let where_: String
    }

    /// The learning path itself, bundled so the contents page is never typed twice.
    static let contentsChapter = Chapter(number: 0, file: "learning-path", summary: "The front door to the living documentation.")

    /// The reading order: the first table of the learning path, one row per chapter.
    static func chapters(from learningPath: MarkdownDocument) -> [Chapter] {
        guard let table = learningPath.blocks.compactMap({ block -> (header: [String], rows: [[String]])? in
            if case let .table(header, rows) = block, header.first == "Step" { return (header, rows) }
            return nil
        }).first else { return [] }
        return table.rows.compactMap { row in
            guard row.count >= 3, let number = Int(row[0]), let file = linkTarget(in: row[1]) else { return nil }
            return Chapter(number: number, file: file.replacingOccurrences(of: ".md", with: ""), summary: row[2])
        }
    }

    /// The Swift vocabulary table: term, meaning, where it appears.
    static func glossary(from learningPath: MarkdownDocument) -> [GlossaryEntry] {
        guard let table = learningPath.blocks.compactMap({ block -> [[String]]? in
            if case let .table(header, rows) = block, header.first == "Term" { return rows }
            return nil
        }).first else { return [] }
        return table.filter { $0.count >= 3 }.map { GlossaryEntry(term: $0[0], meaning: $0[1], where_: $0[2]) }
    }

    /// "[architecture.md](architecture.md)" → "architecture.md".
    static func linkTarget(in cell: String) -> String? {
        guard let open = cell.range(of: "]("), let close = cell.range(of: ")", range: open.upperBound..<cell.endIndex) else { return nil }
        return String(cell[open.upperBound..<close.lowerBound])
    }

    public static func markdownURL(for file: String, in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: file, withExtension: "md", subdirectory: "\(folder)/docs")
    }

    public static func diagramURL(for file: String, index: Int, in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: "\(file)-\(index)", withExtension: "png", subdirectory: "\(folder)/diagrams")
    }

    static func document(for file: String, in bundle: Bundle = .main) -> MarkdownDocument? {
        guard let url = markdownURL(for: file, in: bundle), let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return MarkdownDocument.parse(text)
    }

    /// About 200 words a minute, never under one minute.
    static func readingMinutes(_ document: MarkdownDocument) -> Int {
        readingMinutes(words: document.blocks.reduce(0) { $0 + $1.words })
    }

    static func readingMinutes(words: Int) -> Int {
        max(1, Int((Double(words) / 200).rounded()))
    }

    /// One short page of a chapter: a `##` section, or one part of a long one.
    struct Page: Equatable, Hashable, Identifiable {
        let file: String
        /// The section's heading text, or "Overview" for what sits above the first section.
        let title: String
        let part: Int
        let parts: Int
        /// The section's blocks for this part, without its `##` heading.
        let blocks: [MarkdownDocument.Block]
        /// Position in the chapter's page list, from 0.
        let number: Int
        var id: String { "\(file)#\(number)" }
        var words: Int { blocks.reduce(0) { $0 + $1.words } }
        var minutes: Int { ExplainerLibrary.readingMinutes(words: words) }
        var hasDiagram: Bool { blocks.contains { if case .diagram = $0 { true } else { false } } }
    }

    /// One card in a chapter's list: a section, opening on its first page; Next walks through the rest of its parts.
    /// A split section gets one card, not one per part, since its parts are cut by length and have no names of their own.
    struct Card: Equatable, Identifiable {
        let first: Page
        let parts: Int
        let words: Int
        let hasDiagram: Bool
        var id: String { first.id }
        var minutes: Int { ExplainerLibrary.readingMinutes(words: words) }
    }

    /// The chapter's cards: each run of a section's parts folded into one.
    static func cards(for pages: [Page]) -> [Card] {
        var cards: [Card] = []
        for page in pages {
            if page.part > 1, let last = cards.last, last.first.title == page.title {
                cards[cards.count - 1] = Card(first: last.first, parts: last.parts + 1, words: last.words + page.words,
                                              hasDiagram: last.hasDiagram || page.hasDiagram)
            } else {
                cards.append(Card(first: page, parts: 1, words: page.words, hasDiagram: page.hasDiagram))
            }
        }
        return cards
    }

    /// About a minute and a half of reading; a longer section is split into parts.
    static let pageWords = 300

    /// Chapters whose sections read newest first: the decision log appends at the bottom.
    static let newestFirst: Set<String> = ["decisions"]

    /// The chapter as short pages: an Overview of what precedes the first `##`, then one page per
    /// `##` section (reversed for `newestFirst` files). A section over `pageWords` is split at its
    /// `###` headings, then at block boundaries, and a long table by rows, each part repeating the
    /// header. A block that cannot be cut stays whole on its own page.
    static func pages(of document: MarkdownDocument, file: String) -> [Page] {
        var overview: [MarkdownDocument.Block] = []
        var sections: [(title: String, blocks: [MarkdownDocument.Block])] = []
        var titled = false
        for block in document.blocks {
            if case let .heading(2, text) = block {
                sections.append((text, []))
            } else if sections.isEmpty {
                if case .heading(1, _) = block, !titled { titled = true } else { overview.append(block) }
            } else {
                sections[sections.count - 1].blocks.append(block)
            }
        }
        if newestFirst.contains(file) { sections.reverse() }
        if !overview.isEmpty { sections.insert(("Overview", overview), at: 0) }

        var pages: [Page] = []
        for section in sections {
            let parts = split(section.blocks)
            for (offset, blocks) in parts.enumerated() {
                pages.append(Page(file: file, title: section.title, part: offset + 1, parts: parts.count, blocks: blocks, number: pages.count))
            }
        }
        return pages
    }

    /// A section's blocks in parts of at most `pageWords`: its `###` subsections grouped while they
    /// fit, and any group still too long cut between blocks.
    static func split(_ blocks: [MarkdownDocument.Block]) -> [[MarkdownDocument.Block]] {
        let words = { (blocks: [MarkdownDocument.Block]) in blocks.reduce(0) { $0 + $1.words } }
        guard words(blocks) > pageWords else { return [blocks] }
        var subsections: [[MarkdownDocument.Block]] = [[]]
        for block in blocks {
            if case .heading(3, _) = block, !subsections[subsections.count - 1].isEmpty { subsections.append([]) }
            subsections[subsections.count - 1].append(block)
        }
        var groups: [[MarkdownDocument.Block]] = []
        for subsection in subsections where !subsection.isEmpty {
            if let last = groups.last, words(last) + words(subsection) <= pageWords {
                groups[groups.count - 1] += subsection
            } else {
                groups.append(subsection)
            }
        }
        return groups.flatMap { words($0) > pageWords ? splitBetweenBlocks($0) : [$0] }
    }

    /// Cuts between blocks, never leaving a heading at the foot of a part; a long table is cut by rows.
    private static func splitBetweenBlocks(_ blocks: [MarkdownDocument.Block]) -> [[MarkdownDocument.Block]] {
        var parts: [[MarkdownDocument.Block]] = []
        var current: [MarkdownDocument.Block] = []
        var currentWords = 0
        func close() {
            // Headings at the end move on with the text they introduce.
            var carried: [MarkdownDocument.Block] = []
            while case .heading? = current.last { carried.insert(current.removeLast(), at: 0) }
            if !current.isEmpty { parts.append(current) }
            current = carried
            currentWords = 0
        }
        for block in blocks {
            var pieces = [block]
            if block.words > pageWords, case let .table(header, rows) = block {
                pieces = tableParts(header: header, rows: rows)
            }
            for (offset, piece) in pieces.enumerated() {
                if currentWords > 0, currentWords + piece.words > pageWords { close() }
                current.append(piece)
                currentWords += piece.words
                // Every table part but the last fills a page of its own.
                if offset < pieces.count - 1 { close() }
            }
        }
        if !current.isEmpty { parts.append(current) }
        return parts
    }

    /// A table's rows in runs of at most `pageWords`, each run under the same header.
    private static func tableParts(header: [String], rows: [[String]]) -> [MarkdownDocument.Block] {
        var runs: [[[String]]] = []
        var words = 0
        for row in rows {
            let rowWords = MarkdownDocument.Block.table(header: header, rows: [row]).words
            if let last = runs.last, !last.isEmpty, words + rowWords <= pageWords {
                runs[runs.count - 1].append(row)
                words += rowWords
            } else {
                runs.append([row])
                words = rowWords
            }
        }
        return runs.map { .table(header: header, rows: $0) }
    }
}

/// The contents page: the chapters in reading order, then the Swift vocabulary.
struct ExplainerView: View {
    let onDismiss: () -> Void
    @State private var contents: MarkdownDocument?
    @State private var open: ExplainerLibrary.Chapter?

    /// `initial` opens straight into a chapter by file name; nil shows the contents page.
    init(initial: String? = nil, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        let contents = ExplainerLibrary.document(for: ExplainerLibrary.contentsChapter.file)
        _contents = State(initialValue: contents)
        _open = State(initialValue: contents.flatMap { ExplainerLibrary.chapters(from: $0).first { $0.file == initial } })
    }

    var body: some View {
        NavigationStack {
            Group {
                if let contents {
                    contentsPage(contents)
                } else {
                    Text("The explainer pages are not in this build.").foregroundStyle(.secondary).padding()
                }
            }
            .foregroundStyle(.ivory)
            .background(WoodGrainView().ignoresSafeArea())
            .navigationTitle("How Catch 5 is built")
            .toolbar { Button("Done", action: onDismiss) }
            .navigationDestination(item: $open) { chapter in
                DocumentReaderView(chapter: chapter, chapters: chapters) { open = $0 }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var chapters: [ExplainerLibrary.Chapter] { contents.map(ExplainerLibrary.chapters) ?? [] }

    private func contentsPage(_ contents: MarkdownDocument) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if case let .paragraph(lede)? = contents.blocks.dropFirst().first {
                    MarkdownText(lede).font(.body).opacity(0.85)
                }
                VStack(spacing: 10) {
                    ForEach(chapters) { chapter in
                        Button { open = chapter } label: { chapterCard(chapter) }.buttonStyle(.plain)
                    }
                }
                glossarySection(ExplainerLibrary.glossary(from: contents))
            }
            .padding(16).frame(maxWidth: 640).frame(maxWidth: .infinity)
        }
    }

    private func chapterCard(_ chapter: ExplainerLibrary.Chapter) -> some View {
        let document = ExplainerLibrary.document(for: chapter.file)
        return HStack(alignment: .top, spacing: 14) {
            Text(String(chapter.number)).font(.system(.title2, design: .serif).weight(.bold)).foregroundStyle(Color.suitRed)
                .frame(width: 28, alignment: .trailing)
            VStack(alignment: .leading, spacing: 4) {
                Text(document?.title ?? chapter.file).font(.headline)
                Text(chapter.summary).font(.footnote).opacity(0.8).fixedSize(horizontal: false, vertical: true)
                if let document {
                    Text("\(ExplainerLibrary.readingMinutes(document)) min · \(document.sections.count) sections\(document.diagramCount > 0 ? " · \(document.diagramCount) diagram\(document.diagramCount == 1 ? "" : "s")" : "")")
                        .font(.caption2.monospaced()).opacity(0.55)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.footnote).opacity(0.4)
        }
        .padding(14)
        .background(Theme.Wood.inlay.opacity(0.85), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.ivory.opacity(0.12)))
        .accessibilityElement(children: .combine)
    }

    private func glossarySection(_ entries: [ExplainerLibrary.GlossaryEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SWIFT VOCABULARY").font(.system(.caption2, design: .monospaced).weight(.medium)).tracking(1).opacity(0.6)
            ForEach(entries, id: \.term) { entry in
                VStack(alignment: .leading, spacing: 2) {
                    MarkdownText(entry.term).font(.subheadline.weight(.semibold))
                    MarkdownText(entry.meaning).font(.footnote).opacity(0.85)
                    MarkdownText(entry.where_).font(.caption2).opacity(0.55)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.top, 8)
    }
}

/// One chapter as a list of short pages; tapping a card opens that page on top.
struct DocumentReaderView: View {
    let chapter: ExplainerLibrary.Chapter
    let chapters: [ExplainerLibrary.Chapter]
    /// A link to another doc, or the Previous and Next buttons, opens that chapter in place.
    let openChapter: (ExplainerLibrary.Chapter) -> Void
    @State private var document: MarkdownDocument?
    @State private var pages: [ExplainerLibrary.Page] = []
    @State private var reading: ExplainerLibrary.Page?

    var body: some View {
        ScrollView {
            if let document {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        MarkdownText(document.title).font(.system(.title2, design: .serif).weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        Text(chapter.summary).font(.footnote).opacity(0.8).fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(spacing: 10) {
                        ForEach(ExplainerLibrary.cards(for: pages)) { card in
                            Button { reading = card.first } label: { pageCard(card) }.buttonStyle(.plain)
                        }
                    }
                    neighbours
                }
                .padding(16).frame(maxWidth: 640).frame(maxWidth: .infinity)
            } else {
                Text("This chapter is not in this build.").foregroundStyle(.secondary).padding()
            }
        }
        .foregroundStyle(.ivory)
        .background(WoodGrainView().ignoresSafeArea())
        .navigationTitle(document?.title ?? "")
        .environment(\.openURL, chapterLinks)
        .navigationDestination(item: $reading) { page in
            PageReaderView(pages: pages, start: page.number, next: nextChapter, close: { reading = nil }, open: open)
                .environment(\.openURL, chapterLinks)
        }
        .task(id: chapter.file) {
            reading = nil
            document = ExplainerLibrary.document(for: chapter.file)
            pages = document.map { ExplainerLibrary.pages(of: $0, file: chapter.file) } ?? []
        }
    }

    /// Leaves any open page, then shows the other chapter's page list.
    private func open(_ other: ExplainerLibrary.Chapter) {
        reading = nil
        openChapter(other)
    }

    /// A relative link to a sibling doc opens that chapter; anything else goes to the system.
    private var chapterLinks: OpenURLAction {
        OpenURLAction { url in
            let target = url.lastPathComponent.replacingOccurrences(of: ".md", with: "")
            if url.scheme == nil || url.isFileURL, let chapter = chapters.first(where: { $0.file == target }) {
                open(chapter)
                return .handled
            }
            return .systemAction
        }
    }

    private var nextChapter: ExplainerLibrary.Chapter? {
        chapters.firstIndex(of: chapter).flatMap { $0 + 1 < chapters.count ? chapters[$0 + 1] : nil }
    }

    private func pageCard(_ card: ExplainerLibrary.Card) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                MarkdownText(card.first.title).font(.headline).multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Text(card.parts > 1 ? "\(card.parts) parts · \(card.minutes) min" : "\(card.minutes) min")
                    if card.hasDiagram {
                        Image(systemName: "point.3.connected.trianglepath.dotted").accessibilityLabel("with a diagram")
                    }
                }
                .font(.caption2.monospaced()).opacity(0.55)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.footnote).opacity(0.4)
        }
        .padding(14)
        .background(Theme.Wood.inlay.opacity(0.85), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.ivory.opacity(0.12)))
        .accessibilityElement(children: .combine)
    }

    private var neighbours: some View {
        let position = chapters.firstIndex(of: chapter)
        let previous = position.flatMap { $0 > 0 ? chapters[$0 - 1] : nil }
        let next = position.flatMap { $0 + 1 < chapters.count ? chapters[$0 + 1] : nil }
        return HStack {
            if let previous {
                Button { open(previous) } label: { Label("Previous", systemImage: "chevron.left") }
                    .buttonStyle(.borderedProminent).tint(Theme.Wood.dark).foregroundStyle(.ivory)
            }
            Spacer()
            if let next {
                Button { open(next) } label: { Label("Next: \(ExplainerLibrary.document(for: next.file)?.title ?? next.file)", systemImage: "chevron.right") }
                    .buttonStyle(.borderedProminent).tint(Color.suitRed).foregroundStyle(.ivory).lineLimit(1)
            }
        }
        .padding(.top, 20)
    }
}


/// One page of a chapter. Previous and Next swap the page in place; before the first page lies the
/// page list, after the last the next chapter.
struct PageReaderView: View {
    let pages: [ExplainerLibrary.Page]
    let next: ExplainerLibrary.Chapter?
    let close: () -> Void
    let open: (ExplainerLibrary.Chapter) -> Void
    @State private var number: Int

    init(pages: [ExplainerLibrary.Page], start: Int, next: ExplainerLibrary.Chapter?, close: @escaping () -> Void,
         open: @escaping (ExplainerLibrary.Chapter) -> Void) {
        self.pages = pages
        self.next = next
        self.close = close
        self.open = open
        _number = State(initialValue: start)
    }

    var body: some View {
        ScrollView {
            if pages.indices.contains(number) {
                let page = pages[number]
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        MarkdownText(page.title).font(.system(.title2, design: .serif).weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        if page.parts > 1 {
                            Text("Part \(page.part) of \(page.parts)").font(.footnote).opacity(0.7)
                        }
                    }
                    ForEach(Array(page.blocks.enumerated()), id: \.offset) { _, block in
                        BlockView(file: page.file, block: block)
                    }
                    turns
                }
                .padding(16).frame(maxWidth: 640).frame(maxWidth: .infinity)
            }
        }
        // A fresh scroll view for each page, so a turned page opens at its top: scrolling the old one to the top in
        // the same update as the turn reached the outgoing page, and the new one kept its offset.
        .id(number)
        .foregroundStyle(.ivory)
        .background(WoodGrainView().ignoresSafeArea())
        .navigationTitle(ExplainerLibrary.document(for: pages.first?.file ?? "")?.title ?? "")
    }

    private var turns: some View {
        HStack {
            Button {
                if number > 0 { number -= 1 } else { close() }
            } label: { Label("Previous", systemImage: "chevron.left") }
                .buttonStyle(.borderedProminent).tint(Theme.Wood.dark).foregroundStyle(.ivory)
                .accessibilityHint(number > 0 ? "The page before" : "Back to the list of pages")
            Spacer()
            if number + 1 < pages.count {
                Button { number += 1 } label: { Label("Next", systemImage: "chevron.right") }
                    .buttonStyle(.borderedProminent).tint(Color.suitRed).foregroundStyle(.ivory)
            } else if let next {
                Button { open(next) } label: { Label("Next: \(ExplainerLibrary.document(for: next.file)?.title ?? next.file)", systemImage: "chevron.right") }
                    .buttonStyle(.borderedProminent).tint(Color.suitRed).foregroundStyle(.ivory).lineLimit(1)
            }
        }
        .padding(.top, 20)
    }

}

/// One Markdown block drawn natively; diagrams load from the chapter's rendered PNGs.
struct BlockView: View {
    let file: String
    let block: MarkdownDocument.Block

    var body: some View {
        switch block {
        case let .heading(level, text):
            if level == 1 {
                EmptyView()   // the navigation title carries it
            } else {
                MarkdownText(text)
                    .font(level == 2 ? .system(.title2, design: .serif).weight(.semibold) : .headline)
                    .padding(.top, level == 2 ? 14 : 6)
                    .accessibilityAddTraits(.isHeader)
            }
        case let .paragraph(text):
            MarkdownText(text).font(.body).lineSpacing(3).opacity(0.92)
        case let .bullets(items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•").foregroundStyle(Color.suitRed)
                        MarkdownText(item).font(.body).opacity(0.92)
                    }
                }
            }
        case let .numbered(items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(index + 1).").font(.body.monospacedDigit()).foregroundStyle(Color.suitRed).frame(width: 24, alignment: .trailing)
                        MarkdownText(item).font(.body).opacity(0.92)
                    }
                }
            }
        case let .table(header, rows):
            // Tables become stacked rows on the phone: each row a small card of label and value pairs.
            VStack(spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(row.enumerated()), id: \.offset) { column, cell in
                            if !cell.isEmpty {
                                if column == 0 {
                                    MarkdownText(cell).font(.subheadline.weight(.semibold))
                                } else {
                                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                                        if column < header.count, header.count > 2 {
                                            Text(header[column].uppercased()).font(.system(.caption2, design: .monospaced)).opacity(0.5)
                                        }
                                        MarkdownText(cell).font(.footnote).opacity(0.85)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityElement(children: .combine)
                }
            }
        case let .code(language, text):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text).font(.system(.footnote, design: .monospaced)).textSelection(.enabled)
                    .padding(12)
            }
            .background(Theme.Wood.inlay.opacity(0.85), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if !language.isEmpty { Text(language).font(.system(.caption2, design: .monospaced)).opacity(0.4).padding(6) }
            }
            .accessibilityLabel("\(language.isEmpty ? "Code" : language) block")
            .accessibilityValue(text)
        case let .diagram(index):
            DiagramView(file: file, index: index)
        }
    }
}

/// A rendered Mermaid diagram: fitted to the width, and a tap enlarges it to scroll sideways.
struct DiagramView: View {
    let file: String
    let index: Int
    @State private var enlarged = false
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let url = ExplainerLibrary.diagramURL(for: file, index: index), let image = platformImage(at: url) {
            Group {
                if enlarged {
                    ScrollView(.horizontal, showsIndicators: true) {
                        image.resizable().scaledToFit().frame(height: 480).padding(10)
                    }
                } else {
                    image.resizable().scaledToFit().padding(10)
                }
            }
            .background(.ivory.opacity(contrast == .increased ? 1 : 0.94), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: enlarged ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.caption).foregroundStyle(.black.opacity(0.55)).padding(8)
            }
            .onTapGesture { withAnimation(reduceMotion ? Theme.Motion.reduced : Theme.Motion.overlay) { enlarged.toggle() } }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Diagram \(index)")
            .accessibilityHint(enlarged ? "Double tap to fit the width" : "Double tap to enlarge")
            .accessibilityAddTraits(.isButton)
        } else {
            Text("Diagram \(index) is not in this build.").font(.footnote).opacity(0.6)
        }
    }

    private func platformImage(at url: URL) -> Image? {
        #if canImport(UIKit)
        return UIImage(contentsOfFile: url.path).map(Image.init(uiImage:))
        #else
        return NSImage(contentsOf: url).map(Image.init(nsImage:))
        #endif
    }
}

/// Inline Markdown (bold, italic, code, links) through `AttributedString`; falls back to the raw text.
struct MarkdownText: View {
    let source: String
    init(_ source: String) { self.source = source }
    var body: some View {
        Text(Self.styled(source)).tint(Color.suitRed)
    }

    /// Inline Markdown as an attributed string; code spans get their font here, explicitly, so only
    /// they turn monospaced. Unparseable text is shown as it is.
    static func styled(_ source: String) -> AttributedString {
        guard var attributed = try? AttributedString(markdown: source, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) else {
            return AttributedString(source)
        }
        for run in attributed.runs where run.inlinePresentationIntent?.contains(.code) == true {
            attributed[run.range].font = .system(.body, design: .monospaced).weight(.medium)
            attributed[run.range].foregroundColor = Color.suitRed
        }
        return attributed
    }
}

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
