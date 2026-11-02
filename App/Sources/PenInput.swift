import PencilKit
import SwiftUI
import UIKit
import Vision

/// A paper box she writes in with a finger or a pencil (F2, AC-S3). After a short pause it reports the drawing.
struct WritingPad: UIViewRepresentable {
    /// Change this number to wipe the pad.
    var clearToken: Int
    var lineWidth: CGFloat = 14
    /// Called about a second after she stops writing, with what she drew.
    var onPause: ((PKDrawing) -> Void)?

    func makeUIView(context: Context) -> PKCanvasView {
        let v = PKCanvasView()
        v.drawingPolicy = .anyInput
        v.tool = PKInkingTool(.pen, color: UIColor(red: 0.23, green: 0.16, blue: 0.13, alpha: 1), width: lineWidth)
        v.backgroundColor = .clear
        v.isOpaque = false
        v.isScrollEnabled = false
        v.delegate = context.coordinator
        context.coordinator.lastClear = clearToken
        return v
    }

    func updateUIView(_ v: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.lastClear != clearToken {
            context.coordinator.lastClear = clearToken
            context.coordinator.timer?.invalidate()
            v.drawing = PKDrawing()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: WritingPad
        var lastClear = 0
        var timer: Timer?

        init(_ parent: WritingPad) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            timer?.invalidate()
            guard !canvasView.drawing.strokes.isEmpty, let onPause = parent.onPause else { return }
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak canvasView] _ in
                guard let d = canvasView?.drawing else { return }
                onPause(d)
            }
        }
    }
}

/// Reads a handwritten number or sign on the device (Vision; nothing leaves the iPad).
enum Handwriting {
    static func read(_ drawing: PKDrawing, wantsSign: Bool, completion: @escaping (String?) -> Void) {
        guard !drawing.strokes.isEmpty else { completion(nil); return }
        let bounds = drawing.bounds.insetBy(dx: -30, dy: -30)
        let ink = drawing.image(from: bounds, scale: 2)
        // Dark ink on white paper reads best.
        let paper = UIGraphicsImageRenderer(size: bounds.size).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: bounds.size))
            ink.draw(in: CGRect(origin: .zero, size: bounds.size))
        }
        guard let cg = paper.cgImage else { completion(nil); return }
        let request = VNRecognizeTextRequest { req, _ in
            let candidates = (req.results as? [VNRecognizedTextObservation] ?? [])
                .flatMap { $0.topCandidates(5).map(\.string) }
            let result = candidates.lazy.compactMap { normalize($0, wantsSign: wantsSign) }.first
            DispatchQueue.main.async { completion(result) }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.1
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try VNImageRequestHandler(cgImage: cg, options: [:]).perform([request])
            } catch {
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

    /// Turns what Vision read into a number (or a sign), fixing the usual mix-ups of a child's handwriting.
    static func normalize(_ raw: String, wantsSign: Bool) -> String? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if wantsSign {
            switch s {
            case "+", "t", "T": return "+"
            case "-", "−", "—", "–", "_", "~": return "−"
            case "x", "X", "×", "*": return "×"
            case "÷", "/", ":": return "÷"
            default: return nil
            }
        }
        let map: [Character: Character] = ["O": "0", "o": "0", "D": "0", "l": "1", "I": "1", "|": "1", "i": "1",
                                           "Z": "2", "z": "2", "S": "5", "s": "5", "b": "6", "G": "6", "B": "8",
                                           "g": "9", "q": "9", "T": "7"]
        let digits = String(s.compactMap { ch -> Character? in
            if ch.isNumber { return ch }
            return map[ch]
        })
        guard !digits.isEmpty, digits.count <= 3, Int(digits) != nil else { return nil }
        return String(Int(digits) ?? 0)
    }
}
