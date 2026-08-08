<!-- Banner Video -->
<p align="center">
  <!-- Replace VIDEO_URL with a public URL to your MP4 (e.g., GitHub asset or CDN). Local absolute paths won't work on GitHub. -->
  <a href="VIDEO_URL">
    <!-- Optional: Replace THUMBNAIL_URL with an image preview hosted in the repo (e.g., assets/banner.png). -->
    <img src="THUMBNAIL_URL" alt="Rep Desktop Helper Demo" width="800"/>
  </a>
</p>

<!-- Fallback direct link to the video if thumbnail isn't set -->
<p align="center">
  <a href="VIDEO_URL">Watch the demo video</a>
</p>

# Rep Desktop Helper (macOS)

A macOS desktop helper for the audio transcription feature in the Rep mobile app that captures audio from meetings on your Mac and sends notes to Rep on your iPhone.

## About
This companion app runs on macOS and listens to your microphone during meetings. It streams audio to OpenAI Realtime for low-latency transcription and then summarizes the conversation via a Supabase Edge Function. The resulting notes are sent back to your Rep experience so you can reference them from your iPhone.

## Features
- **Menu Bar Integration:** The app now includes a macOS menu bar extra for quick access to controls, including toggling automatic meeting detection, starting/stopping transcription, and quitting the app.
- **Automatic Meeting Detection:** When enabled, the app detects active meeting providers (Zoom, Teams, Webex, Chrome, etc.) and can automatically start transcribing audio sessions, based on a persistent toggle.
- **Modern macOS UI:** Uses translucent "glass" material design, rounded corners, and adaptive color schemes for a seamless desktop experience.
- **Sign In with Apple:** Secure authentication using Apple ID, with nonce/token handling for privacy and security.

## Architecture Overview
The app is built with Swift/SwiftUI and relies on a few core components:

- Audio capture and processing
  - `AVAudioEngine` captures microphone input.
  - Audio buffers are resampled to 24 kHz mono and converted to PCM16 for efficient transport.
  - Scaled RMS is used to drive UI audio level indicators.

- Realtime transcription (OpenAI Realtime)
  - The app requests an ephemeral token from a Supabase Edge Function.
  - It opens a secure WebSocket to OpenAI Realtime with `intent=transcription`.
  - PCM16 chunks are base64-encoded and sent as `input_audio_buffer.append` events.
  - The app listens for transcription events:
    - `conversation.item.input_audio_transcription.delta` (partial text)
    - `conversation.item.input_audio_transcription.completed` (finalized text)

- Summarization (Supabase Edge Function)
  - When streaming stops, the app commits the audio buffer and composes the full transcript.
  - It sends the transcript to a Supabase Edge Function using SSE (Server-Sent Events).
  - The function returns `response.output_text.delta` events which are appended into a final summary.

- State management
  - `AudioTranscriptionManager` is an `ObservableObject` that owns session state:
    - `isTranscribing`, `isSummarizing`, audio levels, live/finished transcript, and summarized notes.
  - The persistent toggle for automatic detection is saved to UserDefaults (key: `isToggled`) and respected by the detection loop.
  - The menu bar UI is implemented in `RepMenuBar`/`MenuBarView`, showing session state and controls.
  - Swift Concurrency (async/await) is used for networking, streaming, and UI updates.

### Data Flow (high level)
1) Start session
- Request Supabase session (auth) → Edge Function returns an ephemeral OpenAI token.
- Open WebSocket to OpenAI Realtime.

2) Stream audio → text
- Capture mic audio via `AVAudioEngine`.
- Resample to 24 kHz mono, convert to PCM16.
- Send chunks over WebSocket as `input_audio_buffer.append`.
- Receive transcription deltas (update UI) and completion events (append to finished transcript).

3) Stop & summarize
- Stop audio engine and commit buffer.
- Send the full transcript to Supabase Edge Function.
- Consume SSE deltas and produce the final meeting notes.

## Key Files
- `AudioTranscriptionManager.swift`
  - Configures audio session (iOS/tvOS vs macOS behavior), captures audio, sends PCM16 chunks, and manages the WebSocket lifecycle.
  - Decodes transcription events and updates `liveTranscription`/`finishedTranscript`.
  - Posts transcript to Supabase for summarization, consuming SSE deltas.
- `AudioHelpers.swift` (or `AudioTranscriptionHelper`)
  - Buffer resampling, PCM16 conversion, and audio level scaling.
- `SupabaseClientManager.swift`
  - Handles Supabase client/auth and session retrieval.
- `UIComponents.swift` — Contains menu bar UI, Sign In view, and waveform indicator.
- `MenuBarTaskManager.swift` — Manages menu bar logic, process monitoring, and provider window detection.

## Requirements
- Xcode 15+ (Xcode 26 recommended)
- macOS 14+ (Sonoma) or later
- Swift 5.9+
- Supabase project with Auth and Edge Functions
- OpenAI Realtime access (ephemeral token minted server-side)

## Setup
1. Clone the repo:
   ```bash
   git clone https://github.com/Kimchi-Labs/Rep-Desktop-Helper-.git
   cd Rep-Desktop-Helper-
