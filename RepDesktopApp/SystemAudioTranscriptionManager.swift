//
//  SystemAudioTranscriptionManager.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 9/5/26.
/* All requests to the supabase edge functions for the Voice
    transcription with system audio will be handled here */
import Foundation
import AVFoundation
import Combine


final class SystemAudioTranscriptionManager: ObservableObject {
    public init() {}
    
    
    public func startSystemCapture(from sampleBuffer: CMSampleBuffer, webSocketTask: URLSessionWebSocketTask) async throws -> AVAudioPCMBuffer {
        guard let resampleFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24_000, channels: 1, interleaved: false) else { throw ErrorDesc.audioError }
        
        let frame = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        guard let fromPcmBuffer = AVAudioPCMBuffer(pcmFormat: resampleFormat, frameCapacity: frame) else { throw ErrorDesc.audioError }
        
        try sampleBuffer.withAudioBufferList { audioBufferList, _ in
            guard let sourceBuffers = audioBufferList.first else { throw ErrorDesc.bufferError }
            
            guard let sourceData = sourceBuffers.mData else { throw ErrorDesc.bufferError }
            guard let destData = fromPcmBuffer.audioBufferList.pointee.mBuffers.mData else { throw ErrorDesc.bufferError }
            
            memcpy(destData, sourceData, Int(sourceBuffers.mDataByteSize))
            fromPcmBuffer.frameLength = frame
            
            guard let converter = AVAudioConverter(from: fromPcmBuffer.format, to: resampleFormat) else { throw ErrorDesc.configError }
            
            let resampledBuffer = try AudioTranscriptionHelper.resampleBuffer(fromPcmBuffer, converter: converter, outputFormat: resampleFormat)
            let getPcmData: AudioBufferData = try AudioTranscriptionHelper.convertBufferToPCM16Data(resampledBuffer)
            
            let pcmData: Data = getPcmData.data
            let pcmRms: Float = getPcmData.rms
            
            let getAudioLevels = AudioTranscriptionHelper.scaleAudioWaves(rms: pcmRms)
            
            Task { @MainActor in
                AudioTranscriptionManager.shared.audioLevels = CGFloat(getAudioLevels)
            }
            
            Task {
                try? await AudioTranscriptionHelper.sendAudioChunk(pcmData, webSocketTask: webSocketTask)
            }
        }
        return fromPcmBuffer
    }
}
    