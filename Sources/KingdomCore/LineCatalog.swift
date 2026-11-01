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

    public init(lines: [LineID: Line], heroName: String = "Siara") {
        self.lines = lines
        self.heroName = heroName
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
        if heroName != "Siara" { text = text.replacingOccurrences(of: "Siara", with: heroName) }
        return SpokenLine(id: id, speaker: line.speaker, text: text)
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
