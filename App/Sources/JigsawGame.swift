import KingdomCore
import SwiftUI
import UIKit

/// One jigsaw being played: where each piece is, the hint ladder, the explain moment and the companion's slip.
@MainActor
final class JigsawGame: ObservableObject {

    struct Piece: Identifiable, Equatable {
        let id: Int
        var rotation: Int
        var placed = false
        /// Nil until she first drops it somewhere; then whether that first drop fitted (J2 first-fit rate).
        var firstDropFit: Bool?
    }

    enum Overlay: Equatable { case none, explain, slipAsk, slipWhy, done }

    let pictureID: String
    let level: JigsawLevel
    let plan: JigsawCutPlan
    let image: UIImage
    let slipDue: Bool
    @Published var pieces: [Piece]
    /// Tray slots, in order: edge pieces first when the edges are sorted.
    let trayOrder: [Int]
    @Published var hintTarget: Int?
    @Published var hintStep = 0
    @Published var hintsUsed = 0
    @Published var maxHintStep = 0
    @Published var overlay: Overlay = .none
    @Published var missesInARow = 0
    @Published var wobble: Int?
    @Published var slipPiece: Int?
    @Published var slipSlot: Int?
    private(set) var explained = false
    private(set) var slipped = false
    private(set) var strategy: String?

    init(picture: String, level: JigsawLevel, seed: UInt64, slipDue: Bool, image: UIImage) {
        self.pictureID = picture
        self.level = level
        self.image = image
        self.slipDue = slipDue
        plan = JigsawCutPlan(pieces: level.pieces, seed: seed)
        var rng = SeededRandom(seed: seed &+ 99)
        let n = plan.count
        let turning = level.turning
        pieces = (0..<n).map { i in Piece(id: i, rotation: turning ? [90, 180, 270, 0, 90][Int.random(in: 0..<5, using: &rng)] : 0) }
        var order = Array(0..<n).shuffled(using: &rng)
        if level.edgesSorted {
            let p = plan
            order = order.filter { p.isEdge($0) } + order.filter { !p.isEdge($0) }
        }
        trayOrder = order
    }

    var placedCount: Int { pieces.filter(\.placed).count }
    var isFinished: Bool { placedCount == pieces.count }

    // MARK: Moves

    /// A piece dropped on a slot. It fits only in its own slot, the right way up (J1).
    @discardableResult
    func drop(_ piece: Int, on slot: Int?) -> Bool {
        guard !pieces[piece].placed else { return false }
        let fits = slot == piece && pieces[piece].rotation % 360 == 0
        if pieces[piece].firstDropFit == nil { pieces[piece].firstDropFit = fits }
        if fits {
            pieces[piece].placed = true
            missesInARow = 0
            if hintTarget == piece { hintTarget = nil; hintStep = 0 }
            afterPlacement()
        } else {
            missesInARow += 1
            wobble = piece
        }
        return fits
    }

    func turn(_ piece: Int) {
        guard level.turning, !pieces[piece].placed else { return }
        pieces[piece].rotation = (pieces[piece].rotation + 90) % 360
    }

    private func afterPlacement() {
        if isFinished { overlay = .done; return }
        let n = pieces.count
        if slipDue && !slipped && placedCount >= max(2, n / 3) {
            slipped = true
            startSlip()
        } else if !explained && placedCount >= n / 2 {
            explained = true
            overlay = .explain
        }
    }

    // MARK: Hints (J3): strategy, area, outline, then the piece slides home. Never solves the puzzle.

    /// The piece a hint is about: the one she last touched, else the next unplaced one in the tray.
    func nextHintTarget(lastTouched: Int?) -> Int? {
        if let t = hintTarget, !pieces[t].placed { return t }
        if let l = lastTouched, !pieces[l].placed { return l }
        return trayOrder.first { !pieces[$0].placed }
    }

    /// Moves one step up the ladder for the target and returns the step.
    func hint(lastTouched: Int?) -> JigsawHint? {
        guard let t = nextHintTarget(lastTouched: lastTouched) else { return nil }
        if hintTarget != t { hintTarget = t; hintStep = 0 }
        hintStep = min(4, hintStep + 1)
        hintsUsed += 1
        maxHintStep = max(maxHintStep, hintStep)
        let step = JigsawHint(rawValue: hintStep) ?? .strategy
        if step == .slideHome {
            pieces[t].rotation = 0
            if pieces[t].firstDropFit == nil { pieces[t].firstDropFit = false }
            pieces[t].placed = true
            hintTarget = nil
            hintStep = 0
            afterPlacement()
        }
        return step
    }

    /// The spoken strategy for the first hint step.
    func strategyLine(for piece: Int) -> LineID {
        if pieces[piece].rotation != 0 { return "jig.hint.turn" }
        return plan.isEdge(piece) ? "jig.hint.edges" : "jig.hint.colour"
    }

    // MARK: Explain moment (J4) and the companion's slip (J5)

    func explain(_ choice: String) {
        strategy = choice
        overlay = .none
    }

    private func startSlip() {
        // The companion picks an unplaced piece and a wrong slot for it.
        guard let p = trayOrder.first(where: { !pieces[$0].placed }) else { return }
        slipPiece = p
        slipSlot = (0..<pieces.count).first { $0 != p && !pieces[$0].placed } ?? (p + 1) % pieces.count
        overlay = .slipAsk
    }

    func slipAnswer(fits: Bool) {
        overlay = fits ? .none : .slipWhy
        if fits { endSlip() }
    }

    func endSlip() {
        slipPiece = nil
        slipSlot = nil
        if overlay != .done { overlay = .none }
        if !explained && placedCount >= pieces.count / 2 && !isFinished {
            explained = true
            overlay = .explain
        }
    }

    func result(at date: Date) -> JigsawResult {
        return JigsawResult(kind: "picture", pictureID: pictureID, pieces: pieces.count,
                            firstFits: pieces.filter { $0.firstDropFit == true }.count, hintsUsed: hintsUsed,
                            maxHintStep: maxHintStep, strategy: strategy, date: date)
    }
}
