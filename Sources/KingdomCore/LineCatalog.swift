import Foundation

/// A line ready to speak: who says it and the final text.
public struct SpokenLine: Equatable, Sendable {
    public let id: LineID
    public let speaker: Speaker
    public let text: String

    public init(id: LineID, speaker: Speaker, text: String) {
        self.id = id
        self.speaker = speaker
        self.text = text
    }

    /// False for text the voice has nothing to say for (empty, spaces, punctuation only). Handing such
    /// text to the synthesizer gives a zero-length audio buffer and no "finished" callback, which hung
    /// screens that wait for the voice (2026-11-02).
    public var isSpeakable: Bool {
        text.contains { $0.isLetter || $0.isNumber }
    }

    /// The longest the voice should need for this text at `rate` (AVSpeech rate, 0.5 is normal), with
    /// plenty of slack. The speech player moves on after this even if the system never reports the end,
    /// so no screen can wait on the voice forever.
    public func watchdogSeconds(rate: Float) -> Double {
        let words = max(1, text.split(whereSeparator: { $0 == " " }).count)
        let perWord = 0.6 * 0.5 / Double(max(rate, 0.1))
        return min(30, 3 + Double(words) * perWord)
    }

    /// The line cut into sentences, so the voice can pause between them like a storyteller.
    /// "Five stars! The last number tells how many." becomes two parts.
    public var sentences: [SpokenLine] {
        var parts: [String] = []
        var current = ""
        let chars = Array(text)
        for (i, ch) in chars.enumerated() {
            current.append(ch)
            let ends = ch == "." || ch == "!" || ch == "?"
            let nextIsSpace = i + 1 < chars.count && chars[i + 1] == " "
            if ends && nextIsSpace {
                parts.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            }
        }
        let rest = current.trimmingCharacters(in: .whitespaces)
        if !rest.isEmpty { parts.append(rest) }
        if parts.count <= 1 { return [self] }
        return parts.map { SpokenLine(id: id, speaker: speaker, text: $0) }
    }
}

/// Resolves line IDs to text, fills in numbers, and picks the most specific
/// variant of prompts, hints and praise.
public struct LineCatalog: Sendable {
    public let lines: [LineID: Line]
    public let heroName: String
    public let companion: Companion

    public init(lines: [LineID: Line], heroName: String = "Siara", companion: Companion = .unicorn) {
        self.lines = lines
        self.heroName = heroName
        self.companion = companion
    }

    public func spoken(_ id: LineID, item: Item? = nil, n: Int? = nil) -> SpokenLine? {
        guard let line = lines[id] else { return nil }
        var text = line.text
        if let item {
            text = text
                .replacingOccurrences(of: "{a}", with: String(item.a))
                .replacingOccurrences(of: "{b}", with: String(item.b))
                .replacingOccurrences(of: "{answer}", with: String(item.answer))
        }
        if let n { text = text.replacingOccurrences(of: "{n}", with: String(n)) }
        text = text.replacingOccurrences(of: "{companion}", with: companion.name)
        if heroName != "Siara" { text = text.replacingOccurrences(of: "Siara", with: heroName) }
        return SpokenLine(id: id, speaker: line.speaker, text: text)
    }

    /// A line with two numbers that don't come from a scene item (Puzzle Board stories).
    public func spoken(_ id: LineID, a: Int, b: Int) -> SpokenLine? {
        guard let s = spoken(id) else { return nil }
        let text = s.text
            .replacingOccurrences(of: "{a}", with: String(a))
            .replacingOccurrences(of: "{b}", with: String(b))
        return SpokenLine(id: id, speaker: s.speaker, text: text)
    }

    /// Picks `base.kind.level`, then `base.kind`, then `base`.
    public static func mostSpecific(_ base: String, kind: ActivityKind, level: CPALevel, lines: [LineID: Line]) -> LineID? {
        let levelName = String(describing: level)
        for id in ["\(base).\(kind.rawValue).\(levelName)", "\(base).\(kind.rawValue)", base] where lines[id] != nil {
            return id
        }
        return nil
    }

    public static func promptID(for kind: ActivityKind, level: CPALevel, lines: [LineID: Line]) -> LineID? {
        let levelName = String(describing: level)
        for id in ["prompt.\(kind.rawValue).\(levelName)", "prompt.\(kind.rawValue)"] where lines[id] != nil {
            return id
        }
        return nil
    }

    public func prompt(for item: Item, level: CPALevel) -> SpokenLine? {
        LineCatalog.promptID(for: item.kind, level: level, lines: lines).flatMap { spoken($0, item: item) }
    }

    /// The short how-to, said once she has heard the full one twice in a scene (change list item 8).
    /// Picks `prompt.kind.level.short`, then `prompt.kind.short`, else the full prompt.
    public static func shortPromptID(for kind: ActivityKind, level: CPALevel, lines: [LineID: Line]) -> LineID? {
        let levelName = String(describing: level)
        for id in ["prompt.\(kind.rawValue).\(levelName).short", "prompt.\(kind.rawValue).short"] where lines[id] != nil {
            return id
        }
        return promptID(for: kind, level: level, lines: lines)
    }

    /// The prompt for the `n`th time (from 0) this kind and level is asked in a scene: full twice, then short.
    public func prompt(for item: Item, level: CPALevel, timesAsked n: Int) -> SpokenLine? {
        guard n >= 2 else { return prompt(for: item, level: level) }
        return LineCatalog.shortPromptID(for: item.kind, level: level, lines: lines).flatMap { spoken($0, item: item) }
    }

    public func hint(_ stage: HintStage, for item: Item, level: CPALevel) -> SpokenLine? {
        let base: String
        switch stage {
        case .modelHint: base = "hint.model"
        case .workedStep: base = "hint.worked"
        case .showAnswer: base = "reveal"
        }
        return LineCatalog.mostSpecific(base, kind: item.kind, level: level, lines: lines).flatMap { spoken($0, item: item) }
    }

    /// Praise names what she did when a kind-specific line exists; otherwise rotates general praise.
    /// Praise for a right answer. The kind's teaching praise (for example "The last number tells how many")
    /// is used when `teach` is true; otherwise a general praise line. Callers teach once per scene per kind.
    public func praise(for item: Item, level: CPALevel, variant: Int, teach: Bool) -> SpokenLine? {
        if teach, let id = LineCatalog.mostSpecific("praise", kind: item.kind, level: level, lines: lines), id != "praise" {
            return spoken(id, item: item)
        }
        let general = lines.keys.filter { $0.hasPrefix("praise.") && Int($0.dropFirst("praise.".count)) != nil }.sorted()
        guard !general.isEmpty else { return nil }
        return spoken(general[abs(variant) % general.count], item: item)
    }

    public func praise(for item: Item, level: CPALevel, variant: Int) -> SpokenLine? {
        if let id = LineCatalog.mostSpecific("praise", kind: item.kind, level: level, lines: lines), id != "praise",
           variant % 2 == 0 {
            return spoken(id, item: item)
        }
        let general = lines.keys.filter { $0.hasPrefix("praise.") && Int($0.dropFirst("praise.".count)) != nil }.sorted()
        guard !general.isEmpty else { return nil }
        return spoken(general[abs(variant) % general.count], item: item)
    }

    public func number(_ n: Int) -> SpokenLine? { spoken("number.\(n)") ?? SpokenLine(id: "number.\(n)", speaker: .sparkle, text: String(n)) }
    public func count(_ n: Int) -> SpokenLine? { spoken("count.\(n)") ?? number(n) }
}
