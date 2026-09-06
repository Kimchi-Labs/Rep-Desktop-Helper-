//
//  AudioTranscriptionManager.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/4/26.
//

/* All requests to the supabase edge functions for the Voice
 transcription with External Audio mics will be handled here, also
 contains some shared functions with the system audio function */
import Foundation
import Supabase
import SwiftData
import Combine
@preconcurrency import AVFoundation
import ScreenCaptureKit

//TODO: enable external audio mics as a option for rep desktop, not only system audio, also move shared functions into helper

@MainActor
public final class AudioTranscriptionManager: ObservableObject {
    private init() {}
    public static let shared = AudioTranscriptionManager()
    
    private(set) var idempotentKey: UUID?
    private var audioStartedAt: Date?
    private var webSocketTask: URLSessionWebSocketTask?
    typealias MessageTranscription = URLSessionWebSocketTask.Message
    
    @Published public var liveTranscription: String = ""
    @Published var finishedTranscript: String = ""
    @Published var isTranscriptFinished: Bool = false
    @Published var isTranscribing: Bool = false
    @Published var isSummarizing: Bool = false
    @Published var audioLevels: CGFloat = 0
    @Published var summarizedNotes: String = ""
    @Published var didStopAudioStream: Bool = false
    @Published var isRecording = false
    @Published var isPaused = true
    @Published var isMoreCreditsNeeded: Bool = false
    
    
    private let audioEngine = AVAudioEngine()
    
    enum CaptureType {
        case mic
        case system
    }
    
    func audioCaptureRunner(_ sample: CaptureType) async throws {
        switch sample {
        case .mic:
            try? startMicCapture()
            print("external audio from device mic being captured")
        case .system:
            guard let webSocketTask else { throw ErrorDesc.webSocketError }
            try await ScreenAudio.configScreenAudioCapture(webSocketTask: webSocketTask)
            print("system audio being captured")
        }
    }
    
    
    public func startMicCapture() throws {
        let micInput = audioEngine.inputNode
        let micInputFormat = micInput.inputFormat(forBus: 0)
        
        audioEngine.inputNode.removeTap(onBus: 0)
        
        micInput.installTap(onBus: 0, bufferSize: 512, format: micInputFormat) { [weak self] buffer, _ in    //TODO: update to installAudioTap(onBus:bufferSize:format:tapProvider:)
            guard let self else { return }
            
            do {
                guard let resampleAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24_000, channels: 1, interleaved: false) else { throw ErrorDesc.configError }
                guard let converter = AVAudioConverter(from: micInputFormat, to: resampleAudioFormat) else { throw ErrorDesc.configError }
                
                let resampledBuffer = try AudioTranscriptionHelper.resampleBuffer(buffer, converter: converter, outputFormat: resampleAudioFormat)
                let getPcmData: AudioBufferData = try AudioTranscriptionHelper.convertBufferToPCM16Data(resampledBuffer)
                
                let pcmData: Data = getPcmData.data
                let pcmRms: Float = getPcmData.rms
                
                let getAudioLevels = AudioTranscriptionHelper.scaleAudioWaves(rms: pcmRms)
                
                Task { @MainActor in
                    self.audioLevels = CGFloat(getAudioLevels)
                }
                
                Task {
                    try? await AudioTranscriptionHelper.sendAudioChunk(pcmData, webSocketTask: self.webSocketTask)
                }
            } catch {
                print("failed to convert PCM buffer:", error)
            }
        }
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    
    public func openAudioSession() async throws -> AudioSession.SessionData {
        let url: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat-dev")!  //TODO: change back to prod endpoint
        let key: UUID = idempotentKey ?? UUID()
        idempotentKey = key
        var urlRequest: URLRequest = URLRequest(url: url)
        
        let session = try await supabaseDBClient.auth.session
        guard !session.isExpired else { throw ErrorDesc.sessionError }
        
        let token: String = session.accessToken
        guard !token.isEmpty else { throw ErrorDesc.authTokenError }
        
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("audio", forHTTPHeaderField: "x-rep-action")
        urlRequest.setValue(key.uuidString, forHTTPHeaderField: "x-idempotency-key")
        urlRequest.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let urlResponse = response as? HTTPURLResponse else { throw ErrorDesc.serverError }
            let body = String(data: data, encoding: .utf8)
            print("SESSION RESPONSE \(urlResponse.statusCode): \(body ?? "")")
            
            if urlResponse.statusCode == 402 { throw PaymentStoreError.insufficientTokens }
            guard (200...299).contains(urlResponse.statusCode) else { throw ErrorDesc.urlResponseError }
            
            let decodeSession = try JSONDecoder().decode(AudioSession.self, from: data)
            isMoreCreditsNeeded = false
            return decodeSession.session
            
        } catch PaymentStoreError.insufficientTokens {
            isMoreCreditsNeeded = true
            throw PaymentStoreError.insufficientTokens
            
        } catch {
            print("error opening audio session", ErrorDesc.sessionError, error)
            throw error
        }
    }
    
    
    private func sendAudioBillingAction(_ action: String, body: [String: Any]) async throws {
        let url: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat-dev")!
        let session = try await supabaseDBClient.auth.session
        guard !session.isExpired else { throw ErrorDesc.sessionError }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(action, forHTTPHeaderField: "x-rep-action")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw ErrorDesc.serverError }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            print("Audio billing action \(action) failed (\(httpResponse.statusCode)): \(responseBody)")
            throw ErrorDesc.urlResponseError
        }
    }
    
    
    private func finalizeCurrentAudioSession() async throws {
        guard let key = idempotentKey, let startedAt = audioStartedAt else { throw ErrorDesc.nilValue }
        
        let durationSeconds = max(Date().timeIntervalSince(startedAt), 1)
        try await sendAudioBillingAction("audio_finalize", body: ["idempotency_key": key.uuidString, "duration_seconds": durationSeconds])
        
        idempotentKey = nil
        audioStartedAt = nil
    }
    
    
    private func releaseCurrentAudioSession(reason: String) async throws {
        guard let key = idempotentKey else { return }
        
        try await sendAudioBillingAction("audio_release", body: ["idempotency_key": key.uuidString, "reason": reason])
        
        idempotentKey = nil
        audioStartedAt = nil
    }
    
    
    func createWebSocket(urlRequest: URLRequest) -> URLSessionWebSocketTask {
        let socketId: String = UUID().uuidString
        print("new web socket created: \(socketId)")
        return URLSession.shared.webSocketTask(with: urlRequest)
    }
    
    
    func retryWebSocket(urlRequest: URLRequest) async throws {
        webSocketTask?.cancel(with: .goingAway, reason: .none)
        
        let newWebSocket = createWebSocket(urlRequest: urlRequest)
        self.webSocketTask = newWebSocket
        newWebSocket.resume()
        
        print("reconnected to web socket..")
        try await Task.sleep(for: .milliseconds(300))
    }
    
    
    public func startAudioStream(session: AudioSession.SessionData) async throws {
        do {
            liveTranscription.removeAll()
            finishedTranscript.removeAll()
            
            let ephemeralSecret: String = session.value
            guard !ephemeralSecret.isEmpty else { throw ErrorDesc.nilValue }
            
            let openaiTranscriptionUrl: URL = URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!
            var urlRequest: URLRequest = URLRequest(url: openaiTranscriptionUrl)
            
            urlRequest.setValue("Bearer \(ephemeralSecret)", forHTTPHeaderField: "Authorization")
            
            let webSocket = createWebSocket(urlRequest: urlRequest)
            self.webSocketTask = webSocket
            webSocket.resume()
            
            await MainActor.run {
                isTranscribing = true
            }
            
            Task {
                try await transcriptionEventListener(urlRequest: urlRequest)
            }
            
            try await self.audioCaptureRunner(.system)
            audioStartedAt = Date()
            
        } catch {
            print("failed to start stream to openai transcription endpoint ❗️", ErrorDesc.webSocketError, error)
            isTranscribing = false
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            webSocketTask = nil
            
            do {
                try await releaseCurrentAudioSession(reason: "audio_session_start_failed")
            } catch {
                print("failed to release audio reservation after startup failure:", error)
            }
            throw error
        }
    }
    
    
    public func transcriptionEventListener(urlRequest: URLRequest) async throws {
        while isTranscribing {
            guard webSocketTask != nil else { throw ErrorDesc.webSocketError }
            
            do {
                try await extractTranscriptionResponseDelta()
                
                print("connected web socket, response delta being extracted...")
            } catch {
                print("audio stream interrupted ❗️", ErrorDesc.webSocketError, error)
                try await retryWebSocket(urlRequest: urlRequest)
            }
        }
    }
    
    
    public func stopAudioStream(context: ModelContext, onChunk: @escaping (String) async -> Void) async throws {
        do {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            print("socket fully shut for this session")
            
            try await finalizeCurrentAudioSession()
            
            await MainActor.run {
                self.didStopAudioStream = true
                self.isSummarizing = true
            }
            
            try await commitAudioChunk()
            try await Task.sleep(for: .milliseconds(300))
            
            for i in 0..<31 {
                let finished: String = finishedTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if didStopAudioStream && !finished.isEmpty {
                    
                    await MainActor.run { isSummarizing = true }
                    _ = try await summarizeFinishedTranscript(context: context, onChunk: onChunk)
                    
                    await MainActor.run {
                        isSummarizing = false
                        isTranscribing = false
                    }
                    
                    finishedTranscript.removeAll()
                    liveTranscription.removeAll()
                    webSocketTask?.cancel(with: .normalClosure, reason: .none)
                    webSocketTask = nil
                    return
                }
                
                try await Task.sleep(for: .milliseconds(300))
                print("wait loop re-checking: \(i) time(s)")
            }
            
            let live: String = liveTranscription.trimmingCharacters(in: .whitespacesAndNewlines)   ///Fallback if retry loop fails
            if didStopAudioStream && !live.isEmpty {
                finishedTranscript = liveTranscription
                _ = try await summarizeFinishedTranscript(context: context, onChunk: onChunk)
                
                isSummarizing = false
                isTranscribing = false
                finishedTranscript.removeAll()
                liveTranscription.removeAll()
                
                webSocketTask?.cancel(with: .normalClosure, reason: .none)
                webSocketTask = nil
                return
            }
            
        } catch {
            print("failed to summarize finished transcript", ErrorDesc.callsiteError, error)
            throw error
        }
    }
    
    
    public func decodeTranscriptionResponse() async throws -> TranscriptionStream {
        guard let webSocketTask else { throw ErrorDesc.webSocketError }
        let streamMessage: MessageTranscription = try await webSocketTask.receive()
        
        switch streamMessage {
            
        case .data(let data):
            return try JSONDecoder().decode(TranscriptionStream.self, from: data)
            
        case .string(let text):
            guard let text = text.data(using: .utf8) else { throw ErrorDesc.encodeError }
            return try JSONDecoder().decode(TranscriptionStream.self, from: text)
            
        @unknown default:
            throw ErrorDesc.decodeError
        }
    }
    
    
    public func extractTranscriptionResponseDelta() async throws {
        do {
            let response = try await decodeTranscriptionResponse()
            
            try await MainActor.run {
                if response.type == "error" { throw ErrorDesc.extractError }
                print("RESPONSE TYPE: \(response.type)")
                switch response.type {
                case "conversation.item.input_audio_transcription.delta":
                    if let delta = response.delta {
                        self.liveTranscription += delta
                        print("text delta: \(delta)")
                    }
                    
                case "conversation.item.input_audio_transcription.completed":
                    print("audio transcription complete")
                    if let text = response.transcript {
                        self.finishedTranscript += text
                        print("finished transcript:", finishedTranscript)
                    }
                    
                default:
                    print("ignored event:", response.type)
                    break
                }
                print("appending deltas to transcript:", liveTranscription)
            }
            
        } catch {
            print("error extracting objects from transcript", ErrorDesc.extractError, error)
            throw ErrorDesc.extractError
        }
    }
    
    
    public func commitAudioChunk() async throws {
        
        let event: [String: Any] = ["type": "input_audio_buffer.commit"]
        guard !event.isEmpty else { throw ErrorDesc.nilValue }
        
        let jsonData = try JSONSerialization.data(withJSONObject: event)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { throw ErrorDesc.encodeError }
        
        try await webSocketTask?.send(.string(jsonString))
        print("audio stream session commited ✅")
    }
    
    
    public func summarizeFinishedTranscript(context: ModelContext, onChunk: @escaping(String) async -> Void) async throws -> String {  ///shared
        let idempotentKey: UUID = UUID()
        guard !finishedTranscript.isEmpty else { throw ErrorDesc.nilValue }
        
        let fullTranscript: String = finishedTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        print("FULL TRANSCRIPT: \(fullTranscript)")
        await MainActor.run { isSummarizing = false }
        
        let openAIRequest: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat-dev")!  //TODO: change back to prod after
        var urlRequest: URLRequest = URLRequest(url: openAIRequest)
        
        let session = try await supabaseDBClient.auth.session
        let supabaseAccessToken: String = session.accessToken
        
        guard !supabaseAccessToken.isEmpty else { throw ErrorDesc.authTokenError }
        let boundary: String = UUID().uuidString
        
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(supabaseAccessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("chat", forHTTPHeaderField: "x-rep-action")
        urlRequest.setValue("desktop-helper", forHTTPHeaderField: "x-rep-source")
        urlRequest.setValue(idempotentKey.uuidString, forHTTPHeaderField: "x-idempotency-key")
        urlRequest.httpMethod = "POST"
        
        var multipartReqBody = Data()
        
        multipartReqBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        multipartReqBody.append("Content-Disposition: form-data; name=\"input\"\r\n\r\n".data(using: .utf8)!)
        multipartReqBody.append("\(fullTranscript)\r\n".data(using: .utf8)!)
        
        multipartReqBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        multipartReqBody.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        multipartReqBody.append("mini\r\n".data(using: .utf8)!)
        
        multipartReqBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = multipartReqBody
        
        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else { throw ErrorDesc.serverError }
            if httpResponse.statusCode == 402 { throw PaymentStoreError.insufficientTokens }
            print("==========\n status code: \(httpResponse.statusCode)")
            
            for try await stream in bytes.lines {
                print("RESPONSE STREAM: \(stream)")
                guard stream.hasPrefix("data:") else { continue }
                let ssePayload = String(stream.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)    ///strip the "data:" field from the sse payload line
                if ssePayload == "[DONE]" { break }
                
                guard let streamData = ssePayload.data(using: .utf8) else { continue }
                let streamDecoder = try JSONDecoder().decode(StreamEvent.self, from: streamData)
                
                guard streamDecoder.type == "response.output_text.delta", let delta = streamDecoder.delta else { continue }
                await onChunk(delta)
                
                await MainActor.run {
                    isSummarizing = false
                    isTranscriptFinished = true
                    summarizedNotes += delta
                }
            }
            
            try await LocalNotificationsDelegate.shared.requestLocalNotificationPermission()
            try await LocalNotificationsDelegate.shared.notifyNotesSentToMobile()
            
        } catch PaymentStoreError.insufficientTokens {
            isMoreCreditsNeeded = true
            throw PaymentStoreError.insufficientTokens
            
        } catch {
            print("failed to return response ❗️", ErrorDesc.decodeError, error)
            throw ErrorDesc.decodeError
        }
        return ""
    }
}
