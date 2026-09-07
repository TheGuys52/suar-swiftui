import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class AudioNoteService: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    private(set) var isRecording = false
    private(set) var isPlaying = false
    private(set) var playingNoteID: UUID?
    private(set) var elapsed: TimeInterval = 0
    var onRecordingInterrupted: (() -> Void)?
    var onPlaybackFailed: (() -> Void)?

    @ObservationIgnored private var recorder: AVAudioRecorder?
    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var timer: Timer?
    private let session = AVAudioSession.sharedInstance()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(interruptionReceived),
            name: AVAudioSession.interruptionNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(routeChanged),
            name: AVAudioSession.routeChangeNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(mediaServicesReset),
            name: AVAudioSession.mediaServicesWereResetNotification, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func startRecording(at url: URL) throws {
        stopPlayback()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
            let recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            recorder.delegate = self
            guard recorder.prepareToRecord(), recorder.record() else { throw AudioNoteError.cannotRecord }
            self.recorder = recorder
            isRecording = true
            elapsed = 0
            startTimer()
        } catch {
            deactivateSession()
            throw error
        }
    }

    func stopRecording() {
        let activeRecorder = recorder
        recorder = nil
        activeRecorder?.delegate = nil
        activeRecorder?.stop()
        isRecording = false
        stopTimer()
        deactivateSession()
    }

    func duration(at url: URL) throws -> TimeInterval {
        let duration = try AVAudioPlayer(contentsOf: url).duration
        guard duration.isFinite, duration > 0 else { throw AudioNoteError.invalidRecording }
        return duration
    }

    func togglePlayback(noteID: UUID, url: URL) throws {
        guard !isRecording else { return }
        if playingNoteID == noteID, let player {
            if isPlaying {
                player.pause()
                isPlaying = false
                stopTimer()
                deactivateSession()
            } else {
                try activatePlayback()
                guard player.play() else { throw AudioNoteError.cannotPlay }
                isPlaying = true
                startTimer()
            }
            return
        }
        stopPlayback()
        do {
            try activatePlayback()
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            guard player.prepareToPlay(), player.play() else { throw AudioNoteError.cannotPlay }
            self.player = player
            playingNoteID = noteID
            isPlaying = true
            elapsed = 0
            startTimer()
        } catch {
            stopPlayback()
            throw error
        }
    }

    func stopPlayback() {
        player?.delegate = nil
        player?.stop()
        player = nil
        playingNoteID = nil
        isPlaying = false
        if !isRecording {
            stopTimer()
            deactivateSession()
        }
    }

    private func activatePlayback() throws {
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }

    private func deactivateSession() {
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.elapsed = self.recorder?.currentTime ?? self.player?.currentTime ?? 0
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func interrupt() {
        if isRecording { onRecordingInterrupted?() }
        stopPlayback()
    }

    @objc private nonisolated func interruptionReceived(_ notification: Notification) {
        guard let rawValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: rawValue) == .began else { return }
        Task { @MainActor [weak self] in self?.interrupt() }
    }

    @objc private nonisolated func routeChanged(_ notification: Notification) {
        guard let rawValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              AVAudioSession.RouteChangeReason(rawValue: rawValue) == .oldDeviceUnavailable else { return }
        Task { @MainActor [weak self] in self?.interrupt() }
    }

    @objc private nonisolated func mediaServicesReset(_ notification: Notification) {
        Task { @MainActor [weak self] in self?.interrupt() }
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard self?.isRecording == true else { return }
            self?.onRecordingInterrupted?()
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor [weak self] in self?.onRecordingInterrupted?() }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.stopPlayback()
            if !flag { self?.onPlaybackFailed?() }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            self?.stopPlayback()
            self?.onPlaybackFailed?()
        }
    }
}
