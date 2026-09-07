//
//  SpeechRecognitionService.swift
//  Suar
//
//  Created by Adiat Rahman on 07/09/26.
//

import AVFoundation
import Foundation
import Speech

@MainActor
public final class SpeechRecognitionService: ObservableObject {
    @Published public var transcribedText: String = ""
    @Published public private(set) var isRecording: Bool = false
    @Published public var errorMessage: String?

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    public init() {
        speechRecognizer = SFSpeechRecognizer(
            locale: Locale(identifier: "id-ID")
        )
    }
    
    // MARK: - Permission
    
    public func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    // MARK: - Recording
    
    public func startRecording() throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Setup Audio Session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Recognition Request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.requestCreationFailed
        }
        
        // Setup Audio Engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        transcribedText = ""
        errorMessage = nil
        
        // Mulai recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                
                if error != nil || result?.isFinal == true {
                    self.stopRecording()
                }
            }
        }
    }
    
    // Stop recording
    public func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
    }
    
    // MARK: - Error
    
    public enum SpeechError: Error, LocalizedError {
        case requestCreationFailed
        case notAuthorized
        
        public var errorDescription: String? {
            switch self {
            case .requestCreationFailed:
                return "Gagal membuat request speech recognition."
            case .notAuthorized:
                return "Izin speech recognition tidak diberikan."
            }
        }
    }
}
