//
//  AudioHelpers.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/4/26.
//
/* Static data helper functions and classes that are
   shared between system and external audio managers */
import Foundation
import SwiftData
@preconcurrency import AVFoundation
import ScreenCaptureKit


public struct AudioBufferData {
    public let data: Data
    public let rms: Float
}


final class AudioTranscriptionHelper {
    private init() {}

    
    public static func requestMicAccess() async throws {
        let accessGranted = await AVCaptureDevice.requestAccess(for: .audio)
        guard accessGranted else { throw ErrorDesc.audioError }
        
        print("Mic access granted ✅", accessGranted)
    }

    
    nonisolated public static func resampleBuffer(_ inputBuffer: AVAudioPCMBuffer, converter: AVAudioConverter, outputFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let ratio = outputFormat.sampleRate / inputBuffer.format.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCapacity) else { throw ErrorDesc.configError }
        
        var didProvideInput = false
        var error: NSError?
        
        
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if didProvideInput {
                outStatus.pointee = .noDataNow
                return nil
            }
            
            didProvideInput = true
            outStatus.pointee = .haveData
            return inputBuffer
        }
        
        if let error { throw error }
        return outputBuffer
    }
    
    
    public static func convertBufferToPCM16Data(_ buffer: AVAudioPCMBuffer) throws -> AudioBufferData {
        guard let bufferChannelData = buffer.floatChannelData else { throw ErrorDesc.floatError }
        
        let frameLength: Int = Int(buffer.frameLength)
        let channel: UnsafeMutablePointer<Float> = bufferChannelData[0]

        guard frameLength > 0 else { throw ErrorDesc.nilValue }
        
        var sumOfSampleSquares: Float = 0
        var data = Data(capacity: frameLength * 2)
        
        for i in 0..<frameLength {
            let frameSample: Float32 = max(-1.0, min(1.0, channel[i]))
            let frameInt: Int16 = Int16(frameSample * Float(Int16.max))
            
            sumOfSampleSquares += frameSample * frameSample
            
            var littleBytes: Int16 = frameInt.littleEndian
            withUnsafeBytes(of: &littleBytes) { bytes in        ///temporary short-lived pointer
                data.append(contentsOf: bytes)
            }
        }
        let rms: Float = sqrt(sumOfSampleSquares / Float(frameLength))   ///root mean squared sample for audio wave levels UI
        
        return AudioBufferData(data: data, rms: rms)
    }
    
    
    public static func scaleAudioWaves(rms: Float) -> Float {
        let scaledAmplitude: Float = 25
        let audioLevel: Float = min(max(scaledAmplitude * rms, 0), 1)
        
        return audioLevel
    }
    
    
    public static func waveHeight(for index: Int, audioLevel: CGFloat) -> CGFloat {
        let baseHeight: CGFloat = 15
        let maxGrowth: CGFloat = 35
        
        let multipliers: [CGFloat] = [0.42, 0.50, 0.61, 0.70, 0.78, 0.85, 0.80,
                                      0.72, 0.63, 0.58, 0.66, 0.75, 0.86, 0.94,
                                      1.00, 0.92, 0.84, 0.77, 0.82, 0.88, 0.79,
                                      0.68, 0.57, 0.49, 0.54, 0.63, 0.72]
        
        return baseHeight + audioLevel * maxGrowth * multipliers[index]
    }
    
    
    public static func stopSystemStream() async throws {
        do {
            defer { ScreenAudio.clearCaptureSocket() }
            guard let stream = ScreenAudio.stream else { return }
            try stream.removeStreamOutput(ScreenAudio.screenAudio, type: .audio)
            try await stream.stopCapture()
            ScreenAudio.stream = nil
            
            print("system audio from screen recoridng stopped")
        } catch {
            print("failed to stop system stream", ErrorDesc.audioError, error)
        }
    }
    
    
    public static func sendAudioChunk(_ pcm16AudioData: Data, webSocketTask: URLSessionWebSocketTask?) async throws {
        guard let webSocketTask else { throw ErrorDesc.webSocketError }
        
        let base64Audio = pcm16AudioData.base64EncodedString()
        let event: [String: Any] = ["type": "input_audio_buffer.append", "audio": base64Audio]
        
        let jsonData = try JSONSerialization.data(withJSONObject: event)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { throw ErrorDesc.encodeError }
        
        try await webSocketTask.send(.string(jsonString))
        print("sent audio chunk ✅")
    }
}
