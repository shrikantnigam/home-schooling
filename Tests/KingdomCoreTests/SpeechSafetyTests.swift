import XCTest
@testable import KingdomCore

/// Rule 5 check for the hang of 2026-11-02 (a zero-length audio buffer, then a screen stuck waiting for
/// the voice): nothing unspeakable reaches the synthesizer, and every line has a finite watchdog.
final class SpeechSafetyTests: XCTestCase {
    let content = T.content()

    func testPunctuationOnlyTextIsNotSpeakable() {
        for t in ["", " ", "...", "!", " ? ", "—"] {
            XCTAssertFalse(SpokenLine(id: "x", speaker: .narrator, text: t).isSpeakable, "'\(t)'")
        }
        XCTAssertTrue(SpokenLine(id: "x", speaker: .narrator, text: "5").isSpeakable)
        XCTAssertTrue(SpokenLine(id: "x", speaker: .narrator, text: "Yes!").isSpeakable)
    }

    func testSentenceSplitNeverMakesEmptyParts() {
        let l = SpokenLine(id: "x", speaker: .narrator, text: "Five stars! ... The last number tells how many. ")
        for s in l.sentences { XCTAssertFalse(s.text.trimmingCharacters(in: .whitespaces).isEmpty) }
    }

    /// Every line in the app, with numbers filled in, has something to say and a watchdog of 3 to 30 s.
    func testEveryContentLineIsSpeakableWithABoundedWatchdog() {
        let catalog = LineCatalog(lines: content.lines)
        for id in content.lines.keys.sorted() {
            guard let line = catalog.spoken(id, n: 3) else { continue }
            XCTAssertTrue(line.sentences.contains(where: \.isSpeakable), "\(id) has nothing to say")
            for s in line.sentences where s.isSpeakable {
                for rate: Float in [0.3, 0.42, 0.55] {
                    let w = s.watchdogSeconds(rate: rate)
                    XCTAssertGreaterThanOrEqual(w, 3, id)
                    XCTAssertLessThanOrEqual(w, 30, id)
                }
            }
        }
    }

    /// The watchdog leaves time for a slow voice: at least 0.5 s a word at her usual rate.
    func testWatchdogIsGenerousForLongSentences() {
        let text = Array(repeating: "word", count: 20).joined(separator: " ")
        let l = SpokenLine(id: "x", speaker: .narrator, text: text)
        XCTAssertGreaterThanOrEqual(l.watchdogSeconds(rate: 0.42), 3 + 20 * 0.5)
    }
}
