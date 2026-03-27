// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import AVFoundation
import WebKit

@MainActor final class TTSController: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    @Published private(set) var isPlaying = false
    @Published private(set) var isPaused = false

    var isActive: Bool { isPlaying || isPaused }

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public API

    func start(from webView: WKWebView) {
        Task {
            guard let text = try? await webView.evaluateJavaScript("document.body.innerText") as? String,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            stop()
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.voice = AVSpeechSynthesisVoice(language: Locale.preferredLanguages.first)
            synthesizer.speak(utterance)
            isPlaying = true
            isPaused = false
        }
    }

    func togglePlayPause() {
        if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .word)
            isPlaying = false
            isPaused = true
        } else if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPlaying = true
            isPaused = false
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isPaused = false
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isPlaying = false
            self?.isPaused = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isPlaying = false
            self?.isPaused = false
        }
    }
}
