import Foundation
@testable import KingdomCore

enum T {
    static var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return c
    }()

    /// A fixed local date-time.
    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 10, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    static let day1 = date(2026, 11, 2)
    static let day2 = date(2026, 11, 3)

    static var engine: MasteryEngine { MasteryEngine(calendar: calendar) }

    static func content() -> Content { try! Content.bundled() }

    static func result(_ skill: SkillID = "add", level: CPALevel, correct: Bool,
                       needsPractice: Bool = false, date: Date = day1, item: String = "x") -> ItemResult {
        ItemResult(itemID: item, skill: skill, level: level, firstTryCorrect: correct,
                   needsPractice: needsPractice, date: date)
    }

    /// Masters every skill in a chapter: 10 abstract first-try-correct results over two days.
    static func master(_ chapter: ChapterID, in state: inout LearnerState, content: Content) {
        for s in content.skills(in: chapter) {
            var rec = SkillRecord()
            rec.level = .abstract
            for i in 0..<10 {
                rec.history.append(result(s.id, level: .abstract, correct: true, date: i < 5 ? day1 : day2))
            }
            state.skills[s.id] = rec
        }
    }

    static func completeScenes(_ chapter: ChapterID, in state: inout LearnerState, content: Content) {
        for s in content.chapter(chapter)!.scenes { state.completedScenes.insert(s) }
    }
}
