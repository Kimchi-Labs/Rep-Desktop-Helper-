# Rep Desktop Helper

A macOS helper app that captures microphone audio, streams it to OpenAI Realtime for transcription, and summarizes the conversation using Supabase Edge Functions.

## Features
- Live microphone capture with `AVAudioEngine`
- Real‑time transcription over WebSockets to OpenAI Realtime
- SSE streaming summary via Supabase Edge Function
- Swift Concurrency and SwiftData integration

## Requirements
- Xcode 15+ (Xcode 26 recommended)
- macOS 14+ (Sonoma) or later
- Swift 5.9+
- A Supabase project with Auth enabled
- OpenAI Realtime endpoint access (ephemeral token via your Supabase Edge Function)

## Project Structure (high level)
- `AudioTranscriptionManager.swift`: Manages audio session, websocket lifecycle, transcription deltas, and summary requests.
- `AudioTranscriptionHelper.swift`: Buffer resampling/conversion helpers (PCM16), audio level scaling. (If missing, add alongside the manager.)
- App/UI files: SwiftUI views and model integration (not shown here).

## Local Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/Kimchi-Labs/Rep-Desktop-Helper-.git
   cd Rep-Desktop-Helper-
