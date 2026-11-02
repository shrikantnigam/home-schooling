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
    /// The companion's voice pitch (charter v1.3: each companion sounds like itself).
    var companionPitch: Float = 1.3
    var volume: Float = 1

    private let synth = AVSpeechSynthesizer()
    /// Sentences still to speak, with the index of the line each came from.
    private var queue: [(line: SpokenLine, index: Int)] = []
    /// Called as each line starts, with its index in the lines passed to `say`. Drives visuals in step
    /// with the voice (count-along lights), never a fixed timer (operating model 5E).
    private var onLine: ((Int) -> Void)?
    private var lastStartedIndex = -1
    private var completion: (() -> Void)?
    private let instant: Bool
    private var token = 0
    private var currentUtterance: AVSpeechUtterance?
    /// Moves on if the system never reports the end of an utterance (it can drop one silently, e.g.
    /// right after stopSpeaking or during an audio interruption). Without it a screen waiting for the
    /// voice hangs.
    private var watchdog: DispatchWorkItem?

    @Published private(set) var narratorVoice: AVSpeechSynthesisVoice?
    @Published private(set) var sparkleVoice: AVSpeechSynthesisVoice?
    /// The grown-up's picks (Sound and voice); nil lets the app choose.
    private var narratorChoice: String?
    private var companionChoice: String?

    /// Picks both voices again: a grown-up's choice if that voice is still downloaded, else the best one.
    /// Runs at launch, when the choice changes, and when iPadOS reports new voices (Shrikant, 2026-11-02: Ava
    /// downloaded while the app was open was never used, because voices were picked once per launch).
    func chooseVoices(narrator: String?, companion: String?) {
        narratorChoice = narrator
        companionChoice = companion
        narratorVoice = Self.installed(narrator)
            ?? Self.pickVoice(prefer: ["Ava", "Zoe", "Samantha", "Allison", "Serena"], avoid: nil)
        sparkleVoice = Self.installed(companion)
            ?? Self.pickVoice(prefer: ["Nicky", "Evan", "Joelle", "Karen", "Susan"], avoid: narratorVoice?.identifier)
    }

    private static func installed(_ id: String?) -> AVSpeechSynthesisVoice? {
        guard let id else { return nil }
        return AVSpeechSynthesisVoice(identifier: id)
    }

    /// Every downloaded English voice a grown-up can pick, best quality first (no novelty voices).
    static var englishVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") && !$0.voiceTraits.contains(.isNoveltyVoice) }
            .sorted { a, b in
                if a.quality != b.quality { return a.quality.rawValue > b.quality.rawValue }
                if a.language != b.language { return a.language < b.language }
                return a.name < b.name
            }
    }

    /// "Ava · Premium · US", for the grown-ups' list.
    static func describe(_ v: AVSpeechSynthesisVoice) -> String {
        let q: String
        switch v.quality {
        case .premium: q = "Premium"
        case .enhanced: q = "Enhanced"
        default: q = "Basic"
        }
        let region = v.language.split(separator: "-").last.map(String.init) ?? v.language
        return "\(v.name) · \(q) · \(region)"
    }

    /// Plays one sample sentence in a given voice (grown-ups' Play button).
    func sample(_ text: String, voice: AVSpeechSynthesisVoice?, pitch: Float = 1) {
        stop()
        let u = AVSpeechUtterance(string: text)
        u.voice = voice
        u.rate = rate
        u.volume = volume
        u.pitchMultiplier = pitch
        synth.speak(u)
    }

    /// AC-A8: false when no enhanced or premium English voice is downloaded.
    var hasEnhancedVoices: Bool {
        AVSpeechSynthesisVoice.speechVoices().contains { $0.language.hasPrefix("en") && $0.quality != .default }
    }

    /// QA only: no utterance ever reports its end, so only the watchdog moves speech on.
    private let neverFinishes: Bool

    init(instant: Bool, neverFinishes: Bool = false) {
        self.instant = instant
        self.neverFinishes = neverFinishes
        super.init()
        synth.delegate = self
        chooseVoices(narrator: nil, companion: nil)
        NotificationCenter.default.addObserver(forName: AVSpeechSynthesizer.availableVoicesDidChangeNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.chooseVoices(narrator: self.narratorChoice, companion: self.companionChoice)
            }
        }
        if !instant {
            // Set up audio off the main thread. Activating the session on the main thread can stall
            // the first frame (Xcode warns about this), which shows as a blank screen at launch.
            Task.detached(priority: .userInitiated) {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
                try? session.setActive(true)
            }
        }
    }

    /// Speaks lines in order, then calls `then`. Stops anything already playing.
    func say(_ lines: [SpokenLine?], then: (() -> Void)? = nil, each: ((Int) -> Void)? = nil) {
        let wasSpeaking = synth.isSpeaking
        stop()
        // One utterance per sentence, so each can end with a natural pause (see playNext).
        queue = lines.enumerated().flatMap { i, line in
            (line?.sentences ?? []).filter(\.isSpeakable).map { (line: $0, index: i) }
        }
        onLine = each
        lastStartedIndex = -1
        completion = then
        token += 1
        let t = token
        if wasSpeaking && !instant {
            // Speaking straight after stopSpeaking can be dropped by the system; give it a moment.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in self?.playNext(token: t) }
        } else {
            playNext(token: t)
        }
    }

    func say(_ line: SpokenLine?, then: (() -> Void)? = nil) { say([line], then: then) }

    func stop() {
        queue = []
        completion = nil
        onLine = nil
        currentUtterance = nil
        watchdog?.cancel()
        watchdog = nil
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
        let next = queue.removeFirst()
        let line = next.line
        current = line
        isSpeaking = true
        if next.index != lastStartedIndex {
            lastStartedIndex = next.index
            onLine?(next.index)
        }
        if instant {
            if neverFinishes {
                // Like a dropped utterance: no callback. A short watchdog stands in for the real one.
                let u = AVSpeechUtterance(string: line.text)
                currentUtterance = u
                let id = ObjectIdentifier(u)
                let dog = DispatchWorkItem { [weak self] in self?.utteranceDone(id) }
                watchdog = dog
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: dog)
                return
            }
            DispatchQueue.main.async { [weak self] in self?.playNext(token: t) }
            return
        }
        let u = AVSpeechUtterance(string: line.text)
        u.volume = volume
        let last = line.text.last
        // Storyteller delivery: questions a little slower and rising, exclamations a little brighter,
        // and a real pause after each sentence so she has time to look and think.
        let pitchLift: Float = last == "!" ? 1.06 : (last == "?" ? 1.04 : 1.0)
        u.rate = last == "?" ? rate * 0.94 : rate
        switch line.speaker {
        case .narrator:
            u.voice = narratorVoice
            u.pitchMultiplier = 1.0 * pitchLift
        case .sparkle:
            u.voice = sparkleVoice
            // Higher and brighter so Sparkle sounds different even with one default voice.
            u.pitchMultiplier = companionPitch * pitchLift
        }
        let lastInLine = queue.first.map { $0.index != next.index } ?? true
        switch last {
        case "?": u.postUtteranceDelay = 0.7
        case "!": u.postUtteranceDelay = lastInLine ? 0.55 : 0.4
        case ".": u.postUtteranceDelay = lastInLine ? 0.5 : 0.35
        default: u.postUtteranceDelay = 0.25
        }
        currentUtterance = u
        let id = ObjectIdentifier(u)
        let dog = DispatchWorkItem { [weak self] in self?.utteranceDone(id) }
        watchdog?.cancel()
        watchdog = dog
        DispatchQueue.main.asyncAfter(deadline: .now() + line.watchdogSeconds(rate: rate) + u.postUtteranceDelay, execute: dog)
        synth.speak(u)
    }

    /// The current utterance ended: finished, cancelled by the system, or timed out by the watchdog.
    /// Whichever comes first moves on; the others find it no longer current and do nothing.
    fileprivate func utteranceDone(_ id: ObjectIdentifier) {
        guard let cur = currentUtterance, ObjectIdentifier(cur) == id else { return }
        currentUtterance = nil
        watchdog?.cancel()
        watchdog = nil
        playNext(token: token)
    }

    private static func pickVoice(prefer names: [String], avoid: String?) -> AVSpeechSynthesisVoice? {
        // Skip novelty voices (Whisper, Bubbles, Bells and so on). On a simulator or an iPad with no
        // downloaded voices, the old ranking could hand Sparkle one of these, and Whisper is nearly silent.
        let english = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.hasPrefix("en") && $0.identifier != avoid && !$0.voiceTraits.contains(.isNoveltyVoice)
        }
        let ranked = english.sorted { a, b in
            if a.quality != b.quality { return a.quality.rawValue > b.quality.rawValue }
            return (a.language == "en-US" ? 0 : 1) < (b.language == "en-US" ? 0 : 1)
        }
        for name in names {
            if let v = ranked.first(where: { $0.name.hasPrefix(name) && $0.quality != .default }) { return v }
        }
        // No good named voice: Sparkle shares the plain system voice and is told apart by pitch alone.
        if avoid != nil { return AVSpeechSynthesisVoice(language: "en-US") }
        return ranked.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}

extension SpeechPlayer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.utteranceDone(id) }
    }

    /// A cancel we didn't ask for (stop() clears the current utterance first, so ours are ignored).
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.utteranceDone(id) }
    }
}
