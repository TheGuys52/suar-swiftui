//
//  VoiceEditBlockRowView.swift
//  Suar
//
//  Created by Adiat Rahman on 07/09/26.
//

import Speech
import SwiftUI

struct VoiceEditBlockRowView: View {
    let block: ScriptBlock
    let isSelected: Bool
    let onTap: () -> Void
    let onVoiceEdit: (UUID, String) -> Void
    
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var showPermissionAlert = false
    @State private var hasAutoStarted = false
    @State private var silenceTimer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Recording indicator
            if isSelected && speechService.isRecording {
                HStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.system(size: 20))
                        .foregroundStyle(.red)
                    Text("Recording... Mulai bicara")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            
            // Live feedback
            if isSelected && !speechService.transcribedText.isEmpty {
                Text(speechService.transcribedText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
            }
            
            ZStack(alignment: .topLeading) {
                blockContent
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(block.content)
                
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Navigasi — biarkan VoiceOver baca teks
                    }
                    .onLongPressGesture(minimumDuration: 1.0) {
                        onTap()
                    }
            }
            
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .alert("Izin Diperlukan", isPresented: $showPermissionAlert) {
            Button("Buka Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Suar butuh izin Microphone dan Speech Recognition untuk fitur edit suara.")
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue && !hasAutoStarted {
                hasAutoStarted = true
                Task {
                    await startRecordingWithPermission()
                }
            } else if !newValue {
                hasAutoStarted = false
                speechService.stopRecording()
            }
        }
        .onChange(of: speechService.isRecording) { _, isRecording in
            if !isRecording && !speechService.transcribedText.isEmpty {
                let text = speechService.transcribedText
                speechService.transcribedText = ""
                applyVoiceEdit(text)
                announceResult(text)
            }
        }
    }
    
    // MARK: - Speech Handling
    
    private func startRecordingWithPermission() async {
        let authorized = await speechService.requestAuthorization()
        if authorized {
            do {
                try speechService.startRecording()
                silenceTimer?.invalidate()
                silenceTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [speechService] _ in
                    Task { @MainActor in
                        if speechService.isRecording {
                            speechService.stopRecording()
                            UIAccessibility.post(
                                notification: .announcement,
                                argument: "Recording dihentikan."
                            )
                        }
                    }
                }
            } catch {
                speechService.errorMessage = error.localizedDescription
            }
        } else {
            showPermissionAlert = true
        }
    }
    
    private func applyVoiceEdit(_ transcript: String) {
        let original = block.content
        let lowercased = transcript.lowercased().trimmingCharacters(in: .whitespaces)
        
        var newContent: String
        // Add
        if lowercased.hasPrefix("tambahkan") || lowercased.hasPrefix("tambah") {
            let words = transcript.split(separator: " ", maxSplits: 1)
            let textToAdd = words.count > 1 ? String(words[1]) : ""
            newContent = original + ". " + textToAdd
            // Update/Edit
        } else if lowercased.contains("ganti") || lowercased.contains("ubah") || lowercased.contains("edit") {
            var parts: [String] = []

            if lowercased.contains("menjadi") {
                parts = lowercased.components(separatedBy: "menjadi")
            } else if lowercased.contains("jadi") {
                parts = lowercased.components(separatedBy: "jadi")
            } else if lowercased.contains(" ke ") {
                parts = lowercased.components(separatedBy: " ke ")
            } else if lowercased.contains("dengan") {
                parts = lowercased.components(separatedBy: "dengan")
            }

            if parts.count == 2 {
                let oldWord = parts[0]
                    .replacingOccurrences(of: "ganti", with: "")
                    .replacingOccurrences(of: "ubah", with: "")
                    .trimmingCharacters(in: .whitespaces)
                let newWord = parts[1]
                    .trimmingCharacters(in: .whitespaces)
                newContent = original.replacingOccurrences(of: oldWord, with: newWord, options: .caseInsensitive)
            } else if lowercased.hasPrefix("ganti") || lowercased.hasPrefix("ubah") || lowercased.hasPrefix("edit") {
                // Replace seluruh block — tidak ada connector, replace semuanya
                let words = lowercased
                    .replacingOccurrences(of: "ganti", with: "")
                    .replacingOccurrences(of: "ubah", with: "")
                    .replacingOccurrences(of: "edit", with: "")
                    .trimmingCharacters(in: .whitespaces)
                newContent = words
            } else {
                newContent = original
            }
        } else if lowercased.contains("hapus") || lowercased.contains("kosongkan") {
            if lowercased == "hapus" || lowercased == "hapus semua" || lowercased == "kosongkan" {
                newContent = ""
            } else {
                let wordsToDelete = lowercased
                    .replacingOccurrences(of: "hapus", with: "")
                    .trimmingCharacters(in: .whitespaces)
                // Case-insensitive delete
                newContent = original.replacingOccurrences(of: wordsToDelete, with: "", options: .caseInsensitive)
            }
        
        } else {
            newContent = transcript
        }
        
        onVoiceEdit(block.id, newContent)
    }
    
    private func announceResult(_ text: String) {
        UIAccessibility.post(
            notification: .announcement,
            argument: announceResultMessage(text)
        )
    }
    
    private func announceResultMessage(_ text: String) -> String {
        "Berhasil. Perubahan yang dilakukan: \(text)"
    }

    // MARK: - Block Content
    @ViewBuilder
    private var blockContent: some View {
        switch block.blockType {
        case .sceneHeader:
            Text(block.content)
                .font(.headline.bold())
                .foregroundStyle(Color.themeRed)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
            
        case .characterName:
            Text(block.content.uppercased())
                .font(.subheadline.bold())
                .foregroundStyle(Color.themeRed)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 6)
            
        case .dialogue:
            VStack(alignment: .center, spacing: 4) {
                if let characterName = block.characterName {
                    Text(characterName)
                        .font(Font.custom("Courier", size: 20))
                        .foregroundStyle(.primary)
                        .bold()
                }
                if let cue = block.cueDescription {
                    Text(cue)
                        .font(Font.custom("Courier", size: 15))
                        .foregroundStyle(.secondary)
                }
                Text(block.content)
                    .font(Font.custom("Courier", size: 18))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: 280, alignment: .center)
            
        case .stageDirection:
            Text(block.content)
                .font(Font.custom("Courier", size: 18))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
        default:
            Text(block.content)
                .font(Font.custom("Courier", size: 18))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
