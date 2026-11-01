import Foundation

/// All story content: skills, chapters, scenes and spoken lines.
/// Content is data, not code: new chapters are added in content.json.
public struct Content: Codable, Sendable {
    public let skills: [Skill]
    public let chapters: [Chapter]
    public let scenes: [StoryScene]
    public let lines: [LineID: Line]

    public init(skills: [Skill], chapters: [Chapter], scenes: [StoryScene], lines: [LineID: Line]) {
        self.skills = skills
        self.chapters = chapters
        self.scenes = scenes
        self.lines = lines
    }

    public enum LoadError: Error { case missingResource }

    /// Loads the bundled content.json.
    public static func bundled() throws -> Content {
        guard let url = Bundle.module.url(forResource: "content", withExtension: "json") else {
            throw LoadError.missingResource
        }
        return try decode(Data(contentsOf: url))
    }

    public static func decode(_ data: Data) throws -> Content {
        try JSONDecoder().decode(Content.self, from: data)
    }

    // MARK: Lookups

    public func skill(_ id: SkillID) -> Skill? { skills.first { $0.id == id } }
    public func scene(_ id: SceneID) -> StoryScene? { scenes.first { $0.id == id } }
    public func chapter(_ id: ChapterID) -> Chapter? { chapters.first { $0.id == id } }

    public func skills(in chapter: ChapterID) -> [Skill] { skills.filter { $0.chapter == chapter } }

    /// Every item in a chapter's scenes, in story order.
    public func items(in chapter: ChapterID) -> [Item] {
        guard let ch = self.chapter(chapter) else { return [] }
        return ch.scenes.compactMap { scene($0) }.flatMap(\.items)
    }

    public func item(_ id: String) -> Item? {
        for s in scenes { if let i = s.items.first(where: { $0.id == id }) { return i } }
        return nil
    }

    /// The chapter that comes before `chapter`, if any.
    public func previousChapter(of chapter: ChapterID) -> Chapter? {
        guard let i = chapters.firstIndex(where: { $0.id == chapter }), i > 0 else { return nil }
        return chapters[i - 1]
    }

    public func nextChapter(after chapter: ChapterID) -> Chapter? {
        guard let i = chapters.firstIndex(where: { $0.id == chapter }), i + 1 < chapters.count else { return nil }
        return chapters[i + 1]
    }

    /// Problems with the content, for tests. Empty means valid.
    public func validationErrors() -> [String] {
        var errors: [String] = []
        let skillIDs = Set(skills.map(\.id))
        let chapterIDs = Set(chapters.map(\.id))
        var itemIDs = Set<String>()
        for s in skills where !chapterIDs.contains(s.chapter) {
            errors.append("skill \(s.id) has unknown chapter \(s.chapter)")
        }
        for c in chapters {
            for sid in c.scenes {
                guard let s = scene(sid) else { errors.append("chapter \(c.id) lists missing scene \(sid)"); continue }
                if s.chapter != c.id { errors.append("scene \(sid) belongs to \(s.chapter), listed in \(c.id)") }
            }
        }
        for s in scenes {
            for l in s.open + s.payoff + [s.goodbye] where lines[l] == nil {
                errors.append("scene \(s.id) uses missing line \(l)")
            }
            if s.items.isEmpty { errors.append("scene \(s.id) has no items") }
            for i in s.items {
                if !itemIDs.insert(i.id).inserted { errors.append("duplicate item id \(i.id)") }
                if !skillIDs.contains(i.skill) { errors.append("item \(i.id) has unknown skill \(i.skill)") }
                if i.answer < 0 || i.answer > ActivityRules.maxNumber(for: i) {
                    errors.append("item \(i.id) answer \(i.answer) is out of range")
                }
                if LineCatalog.promptID(for: i.kind, level: .abstract, lines: lines) == nil {
                    errors.append("no prompt line for kind \(i.kind.rawValue)")
                }
            }
        }
        return errors
    }
}

public enum ActivityRules {
    /// The largest number an item can show on its number line or tiles.
    public static func maxNumber(for item: Item) -> Int { item.top }

    /// Up to four numeral choices including the answer, in ascending order, all within 0...max.
    /// Deterministic for a given item so a resumed item looks the same.
    public static func choices(for item: Item, count: Int = 4) -> [Int] {
        let maxN = maxNumber(for: item)
        let answer = item.answer
        var picks: Set<Int> = [answer]
        // Nearby distractors first: answer±1, ±2, ±3, alternating by item id hash so the answer
        // is not always in the same slot.
        let seed = item.id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        let offsets = seed % 2 == 0 ? [1, -1, 2, -2, 3, -3, 4, -4, 5, -5] : [-1, 1, -2, 2, -3, 3, -4, 4, 5, -5]
        for o in offsets where picks.count < count {
            let n = answer + o
            if n >= (item.kind == .countTap || item.kind == .howMany || item.kind == .quickLook ? 1 : 0) && n <= maxN {
                picks.insert(n)
            }
        }
        return picks.sorted()
    }
}
