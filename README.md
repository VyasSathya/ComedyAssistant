# Comedy Assistant

A Flutter mobile application designed to help comedians capture, organize, analyze, and prepare their comedy material.

## Overview

Comedy Assistant provides an intuitive platform for comedians at any level to record, transcribe, categorize, and refine their comedy material. The app uses AI-powered analysis to provide insights on comedy structure, themes, and potential improvements.

## Features

### Recording & Transcription
- **Audio Recording**: Capture your comedy ideas with high-quality audio recording
- **Transcription**: Convert recordings to text for easy editing and organization
- **Text Editing**: Refine your material with powerful editing tools

### Content Organization
- **Content Categories**: Organize your material as Jokes, Bits, or Ideas
- **Smart Tagging**: Automatically identify themes and comedy mechanisms
- **Search & Filter**: Easily find material by content, theme, or rating

### Analysis & Insights
- **Performance Metrics**: Get scores and analysis on your comedy material
- **Comedy Structure Analysis**: Identify setup/punchline structure and flow
- **Theme Detection**: Discover recurring themes in your comedy
- **Improvement Suggestions**: Receive targeted tips to improve your material

### Performance Preparation
- **Setlist Creation**: Build and organize performance setlists
- **Timing Estimation**: Track estimated duration of your sets
- **Performance Mode**: Clean, distraction-free interface for live performance

### Additional Features
- **Version History**: Track changes to your material over time
- **Favorites**: Mark your best material for quick access
- **Simple Sharing**: Share your material with other comedians or social media

## Technical Architecture

The app is built with:
- **Flutter**: For cross-platform UI development
- **Provider**: For state management
- **SharedPreferences**: For local data storage
- **Record & Just Audio**: For audio recording and playback
- **Custom Analysis Engine**: For comedy content analysis

## Modules

### 1. Data Models
- `Joke`: For setup/punchline style content
- `Bit`: For longer-form comedy sequences
- `Idea`: For undeveloped comedy concepts
- `Setlist`: For organizing performance material

### 2. Services
- `StorageService`: Manages local data persistence
- `AnalysisService`: Provides comedy content analysis
- `AudioService`: Handles recording and playback functionality

### 3. UI Components
- `RecordPage`: For capturing new material
- `TranscribePage`: For viewing and editing transcriptions
- `CategorizePage`: For categorizing and tagging content
- `LibraryPage`: For browsing and searching all content
- `MaterialDetailPage`: For viewing and editing specific content
- `SetlistPage`: For creating and managing performance setlists
- `SettingsPage`: For configuring app preferences

## Setup and Installation

1. Ensure you have Flutter installed on your development machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Connect a device or emulator
5. Run `flutter run` to start the application

## Dependencies

- flutter: ^3.0.0
- provider: ^6.0.0
- shared_preferences: ^2.0.0
- record: ^4.0.0
- just_audio: ^0.9.0

## Future Enhancements

- Cloud synchronization for multi-device access
- Deep learning-based comedy analysis
- Collaboration features for writing partners
- Performance analytics with audience feedback integration
- Voice analysis for delivery improvement

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

Special thanks to:
- All the comedians who provided feedback during development
- The Flutter community for their excellent packages
- Open source contributors worldwide

---

For support or feature requests, please file an issue on the GitHub repository.