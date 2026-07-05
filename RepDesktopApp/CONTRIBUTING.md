# Contributing to Rep Desktop Helper

Thanks for your interest in contributing! This document outlines the basics to help you get started.

## Branching
- Create feature branches off `main`:
  - `feat/<short-description>` for features
  - `fix/<short-description>` for bug fixes
  - `chore/<short-description>` for maintenance

## Commit Messages
- Use concise, imperative messages:
  - `feat: add websocket reconnection`
  - `fix: handle nil ephemeral token`

## Pull Requests
- Ensure the project builds and runs.
- Include testing notes and screenshots or videos if UI changes are involved.
- Keep PRs focused and small when possible.

## Code Style
- Prefer Swift Concurrency (async/await) where appropriate.
- Use `#Preview` for new SwiftUI previews.
- Keep secrets out of source control.

## Testing
- Add tests using Swift Testing when feasible.
- For networked features, prefer dependency injection and protocol abstractions for easier testing.

## Security
- Do not include API keys or tokens in commits.
- Use environment files or CI secrets for configuration.
