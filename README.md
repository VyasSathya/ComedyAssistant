# Comedy Assistant

A Flutter prototype for capturing, organizing, and preparing comedy material. The source includes recording/transcription screens, joke/bit/idea models, a local library, and setlist UI.

## Explore the implementation

| Area | Source | Role |
| --- | --- | --- |
| App entry and state | [main.dart](lib/main.dart), [AppState](lib/controllers/app_state.dart) | Flutter startup and Provider state |
| Data models | [data_models.dart](lib/models/data_models.dart) | Jokes, bits, ideas, and setlists |
| Local storage | [storage_service.dart](lib/services/storage_service.dart) | Serialization through SharedPreferences |
| Analysis prototype | [analysis_service.dart](lib/services/analysis_service.dart) | Demonstration scoring, labels, and text heuristics |
| Material and setlist screens | [views/](lib/views/) | Recording, categorization, library, detail, settings, and setlists |

The current analysis service is a demonstration implementation, including heuristic and randomized outputs. These scores are not validated measures of audience response or a trained comedy-analysis model.

## Development setup

Install Flutter with a Dart version compatible with the constraint in [pubspec.yaml](pubspec.yaml), currently `>=3.0.0 <4.0.0`.

```sh
flutter pub get
```

The app loads a root `.env` file at startup, and the manifest includes that file as a Flutter asset. Create an untracked local `.env` file before evaluating the app. The combined record/transcribe screen reads `GOOGLE_API_KEY`; no working provider configuration or key is supplied here. Bundled environment values are readable by clients, so privileged server credentials should not be placed in that asset.

With a compatible device or emulator available:

```sh
flutter run
```

Current dependency resolution, microphone permissions, device behavior, and provider integration have not been validated in this documentation review.

## Transcription status

There are separate transcription paths in the source. [transcribe_page.dart](lib/views/transcribe_page.dart) uses demo transcription content and synthetic word timings. [record_and_transcribe_page.dart](lib/views/record_and_transcribe_page.dart) includes a Google API integration path, which requires separate configuration and verification. Neither path is claimed here as an end-to-end tested speech service.

Use synthetic material for screenshots and demo recordings; the app's purpose is to manage writing that may be private. No genuine user material is supplied as a documentation example.

## License

The original README stated MIT, but its referenced `LICENSE` file is absent from this checkout. The owner needs to restore or clarify the intended license notice before offering the source under complete reuse terms.
