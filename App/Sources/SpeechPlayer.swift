import AVFoundation
import KingdomCore
import SwiftUI

/// Speaks every line on the device with AVSpeechSynthesizer (spec section 7).
/// Two different voices: one for the narrator, one for Sparkle (AC-A7).
@MainActor
final class SpeechPlayer: NSObject, ObservableObject {
    /// The line being spoken, for optional subtitles.
    @Published private(set) var current: SpokenLine?
    @Published private(set) var isSpeaking = false

    var rate: Float = 0.42
    var volume: Float = 1

    private let synth = AVSpeechSynthesizer()
    private var queue: [SpokenLine] = []
    private var completion: (() -> Void)?
    private let instant: Bool
    private var token = 0
    private var currentUtterance: AVSpeechUtterance?

    private(set) lazy var narratorVoice: AVSpeechSynthesisVoice? = Self.pickVoice(prefer: ["Ava", "Zoe", "Samantha", "Allison"], avoid: nil)
    private(set) lazy var sparkleVoice: AVSpeechSynthesisVoice? = Self.pickVoice(prefer: ["Nicky", "Evan", "Joelle", "Karen", "Susan"], avoid: narratorVoice?.identifier)

    /// AC-A8: false when no enhanced or premium English voice is downloaded.
    var hasEnhancedVoices: Bool {
        AVSpeechSynthesisVoice.speechVoices().contains { $0.language.hasPrefix("en") && $0.quality != .default }
    }

    init(instant: Bool) {
        self.instant = instant
        super.init()
        synth.delegate = self
        if !instant {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
        }
    }

    /// Speaks lines in order, then calls `then`. Stops anything already playing.
    func say(_ lines: [SpokenLine?], then: (() -> Void)? = nil) {
        stop()
        queue = lines.compactMap { $0 }
        completion = then
        token += 1
        playNext(token: token)
    }

    func say(_ line: SpokenLine?, then: (() -> Void)? = nil) { say([line], then: then) }

    func stop() {
        queue = []
        completion = nil
        currentUtterance = nil
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        isSpeaking = false
    }

    private func playNext(token t: Int) {
        guard t == token else { return }
        guard !queue.isEmpty else {
            isSpeaking = false
            let done = completion
            completion = nil
            done?()
            return
        }
        let line = queue.removeFirst()
        current = line
        isSpeaking = true
        if instant {
            DispatchQueue.main.async { [weak self] in self?.playNext(token: t) }
            return
        }
        let u = AVSpeechUtterance(string: line.text)
        u.rate = rate
        u.volume = volume
        switch line.speaker {
        case .narrator:
            u.voice = narratorVoice
            u.pitchMultiplier = 1.0
        case .sparkle:
            u.voice = sparkleVoice
            // Higher and brighter so Sparkle sounds different even with one default voice.
            u.pitchMultiplier = 1.35
        }
        u.postUtteranceDelay = 0.25
        currentUtterance = u
        synth.speak(u)
    }

    fileprivate func utteranceDone(_ id: ObjectIdentifier) {
        guard let cur = currentUtterance, ObjectIdentifier(cur) == id else { return }
        currentUtterance = nil
        playNext(token: token)
    }

    private static func pickVoice(prefer names: [String], avoid: String?) -> AVSpeechSynthesisVoice? {
        let english = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") && $0.identifier != avoid }
        let ranked = english.sorted { a, b in
            if a.quality != b.quality { return a.quality.rawValue > b.quality.rawValue }
            return (a.language == "en-US" ? 0 : 1) < (b.language == "en-US" ? 0 : 1)
        }
        for name in names {
            if let v = ranked.first(where: { $0.name.hasPrefix(name) && $0.quality != .default }) { return v }
        }
        return ranked.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}

extension SpeechPlayer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.utteranceDone(id) }
    }
}
