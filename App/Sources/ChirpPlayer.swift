import AVFoundation
import Foundation

/// The bird's chirp (cup shuffle, C4). Synthesised once as a short WAV in memory, so the app ships no sound files:
/// two quick rising whistles with a soft attack and release.
@MainActor
final class ChirpPlayer {
    static let shared = ChirpPlayer()

    private var player: AVAudioPlayer?
    /// How many chirps have played (QA reads it; nothing else does).
    private(set) var count = 0

    private init() {
        player = try? AVAudioPlayer(data: Self.makeWAV())
        player?.prepareToPlay()
    }

    func play(volume: Double) {
        count += 1
        guard let player else { return }
        player.volume = Float(min(1, max(0, volume)))
        player.currentTime = 0
        player.play()
    }

    // MARK: Synthesis

    private static let sampleRate = 44_100.0

    /// Two whistles of 90 ms rising from 2.6 kHz to 4.2 kHz, 60 ms apart.
    static func makeWAV() -> Data {
        var samples: [Int16] = []
        func whistle(_ seconds: Double, from f0: Double, to f1: Double) {
            let n = Int(seconds * sampleRate)
            var phase = 0.0
            for i in 0..<n {
                let t = Double(i) / Double(n)
                let f = f0 + (f1 - f0) * t * t
                phase += 2 * Double.pi * f / sampleRate
                // Soft attack and release so it doesn't click.
                let env = min(1, t * 8) * min(1, (1 - t) * 5)
                let v = sin(phase) * env * 0.45 + sin(2 * phase) * env * 0.08
                samples.append(Int16(max(-1, min(1, v)) * Double(Int16.max)))
            }
        }
        func silence(_ seconds: Double) { samples += Array(repeating: 0, count: Int(seconds * sampleRate)) }
        silence(0.01)
        whistle(0.09, from: 2600, to: 4200)
        silence(0.06)
        whistle(0.11, from: 2800, to: 4400)
        silence(0.02)
        return wav(samples)
    }

    private static func wav(_ samples: [Int16]) -> Data {
        var d = Data()
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        let dataBytes = UInt32(samples.count * 2)
        d.append(contentsOf: Array("RIFF".utf8)); u32(36 + dataBytes)
        d.append(contentsOf: Array("WAVE".utf8))
        d.append(contentsOf: Array("fmt ".utf8)); u32(16); u16(1); u16(1)
        u32(UInt32(sampleRate)); u32(UInt32(sampleRate) * 2); u16(2); u16(16)
        d.append(contentsOf: Array("data".utf8)); u32(dataBytes)
        for s in samples { u16(UInt16(bitPattern: s)) }
        return d
    }
}
