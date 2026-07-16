//
//  ContentView.swift
//  RepDesktopApp
//
//  Created by alex haidar on 7/4/26.
//

import SwiftUI
import SwiftData


struct ContentView: View {
    @Environment(\.dismiss) var dismissDesktop
    @Environment(\.modelContext) private var context
    
    @State var audioLevel: Float = 0
    @State var isRecording: Bool = false
    @State var isPaused: Bool = false
    @State private var streamingText: String = ""
    
    @StateObject var audioManager = AudioTranscriptionManager.shared
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Button {
                    dismissDesktop()
                } label: {
                    ZStack {
                        Circle().frame(width: 25, height: 25)
                            .foregroundStyle(Color.clear).glassEffect(.clear)
                        
                        Image(systemName: "xmark").opacity(0.8)
                    }
                    
                }.buttonStyle(.plain)
                
                Spacer()
                
                ZStack() {
                    Capsule()
                        .foregroundStyle(Color.clear).glassEffect(.clear)
                    
                    Text("Currently Transcribing: ").font(.system(size: 12, design: .rounded)).fontWeight(.medium)          //TODO: dynamically pass meeting type
                        .foregroundStyle(Color.kimchilabsReversed).opacity(0.8)
                    
                    
                }.frame(minWidth: 180, maxWidth: 190, maxHeight: 25)
                    .padding(.trailing)
                
            }.padding(.leading, 10)
                .frame(maxWidth: .infinity)
                .padding(.top)
            
            Spacer(minLength: 2)
            
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    
                    HStack {
                        Text("Finished notes will appear in Rep on your\niPhone when you end this transcription.").font(.system(size: 14, design: .rounded)).fontWeight(.medium).opacity(0.5)
                            .padding(.leading, 3)
                        
                        Spacer()
                        Waveform(audioLevel: audioManager.audioLevels, isRecording: audioManager.isTranscribing, isPaused: isPaused)
                            .padding(.trailing, 3)
                    }
                    
                    Button {
                        audioManager.isTranscribing.toggle()
                        Task {
                            if audioManager.isTranscribing {
                                //let desktopAccessToken = try await AuthenticatePairing.desktopAuthPoller()
                                isRecording = true
                                isPaused = false
                                try await AudioTranscriptionHelper.requestMicAccess()
                                let session = try await audioManager.openAudioSession()
                                try await audioManager.startAudioStream(session: session)
                                
                            } else {
                                try await audioManager.stopAudioStream(context: context) { delta in
                                    isRecording = false
                                    isPaused = true
                                    streamingText += delta
                                    audioManager.liveTranscription.removeAll()
                                }
                            }
                        }
                    } label: {
                        
                        if audioManager.isTranscribing {
                            ZStack {
                                Capsule().frame(width: 150, height: 35)
                                    .foregroundStyle(Color.clear).glassEffect(.regular)
                                
                                HStack(alignment: .bottom) {
                                    Text("Stop transcription").font(.system(size: 12, design: .rounded)).fontWeight(.regular)
                                        .foregroundStyle(Color.kimchilabsReversed)
                                    
                                    Image(systemName: "record.circle").foregroundStyle(Color.red)
                                }
                            }
                        } else {
                            ZStack {
                                Capsule().frame(width: 150, height: 35)
                                    .foregroundStyle(Color.kimchilabsReversed)
                                
                                HStack(alignment: .bottom) {
                                    Text("Start Transcribing").font(.system(size: 12, design: .rounded)).fontWeight(.regular)
                                        .foregroundStyle(Color.kimchilabsBackground)
                                    
                                    Image(systemName: "microphone").foregroundStyle(Color.kimchilabsBackground)
                                }
                            }
                        }
                    }.buttonStyle(.plain)
                    
                }.padding(.leading)
                    .padding(.bottom)
                
                Spacer()
                
            }
            
        }.frame(width: 500, height: 180)
            .background(WindowConfigurator())
            .background(Material.ultraThickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        
    }
}

#Preview {
    ContentView()
}
