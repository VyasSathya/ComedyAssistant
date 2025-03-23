// lib/models/data_models.dart
import 'dart:convert';

class ContextMetadata {
  final String linguisticSignature;
  final Map<String, double> contextScores;
  final DateTime extractionTimestamp;

  ContextMetadata({
    this.linguisticSignature = '',
    Map<String, double>? contextScores,
    DateTime? extractionTimestamp,
  })  : contextScores = contextScores ?? {},
        extractionTimestamp = extractionTimestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'linguisticSignature': linguisticSignature,
      'contextScores': contextScores,
      'extractionTimestamp': extractionTimestamp.toIso8601String(),
    };
  }

  factory ContextMetadata.fromJson(Map<String, dynamic> json) {
    return ContextMetadata(
      linguisticSignature: json['linguisticSignature'] ?? '',
      contextScores: Map<String, double>.from(json['contextScores'] ?? {}),
      extractionTimestamp: json['extractionTimestamp'] != null
          ? DateTime.parse(json['extractionTimestamp'])
          : DateTime.now(),
    );
  }
}

class Joke {
  String setup;
  String punchline;
  double score;
  String mechanism;
  List<String> themes;
  List<String> shadowElements;
  Map<String, String>? improvements;
  ContextMetadata? contextMetadata;
  String? recordingPath;
  DateTime createdAt;
  bool isFavorite;

  Joke({
    required this.setup,
    required this.punchline,
    this.score = 0.0,
    this.mechanism = '',
    List<String>? themes,
    List<String>? shadowElements,
    this.improvements,
    this.contextMetadata,
    this.recordingPath,
    DateTime? createdAt,
    this.isFavorite = false,
  })  : themes = themes ?? [],
        shadowElements = shadowElements ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'setup': setup,
      'punchline': punchline,
      'score': score,
      'mechanism': mechanism,
      'themes': themes,
      'shadowElements': shadowElements,
      'improvements': improvements,
      'contextMetadata': contextMetadata?.toJson(),
      'recordingPath': recordingPath,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory Joke.fromJson(Map<String, dynamic> json) {
    return Joke(
      setup: json['setup'] ?? '',
      punchline: json['punchline'] ?? '',
      score: json['score']?.toDouble() ?? 0.0,
      mechanism: json['mechanism'] ?? '',
      themes: List<String>.from(json['themes'] ?? []),
      shadowElements: List<String>.from(json['shadowElements'] ?? []),
      improvements: json['improvements'] != null
          ? Map<String, String>.from(json['improvements'])
          : null,
      contextMetadata: json['contextMetadata'] != null
          ? ContextMetadata.fromJson(json['contextMetadata'])
          : null,
      recordingPath: json['recordingPath'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory Joke.fromJsonString(String jsonString) =>
      Joke.fromJson(jsonDecode(jsonString));
}

class Bit {
  String title;
  String content;
  List<Joke> componentJokes;
  List<String> themes;
  List<String> shadowElements;
  double score;
  Map<String, String>? improvements;
  ContextMetadata? contextMetadata;
  String? recordingPath;
  DateTime createdAt;
  bool isFavorite;

  Bit({
    required this.title,
    required this.content,
    List<Joke>? componentJokes,
    List<String>? themes,
    List<String>? shadowElements,
    this.score = 0.0,
    this.improvements,
    this.contextMetadata,
    this.recordingPath,
    DateTime? createdAt,
    this.isFavorite = false,
  })  : componentJokes = componentJokes ?? [],
        themes = themes ?? [],
        shadowElements = shadowElements ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'componentJokes': componentJokes.map((joke) => joke.toJson()).toList(),
      'themes': themes,
      'shadowElements': shadowElements,
      'score': score,
      'improvements': improvements,
      'contextMetadata': contextMetadata?.toJson(),
      'recordingPath': recordingPath,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory Bit.fromJson(Map<String, dynamic> json) {
    return Bit(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      componentJokes: json['componentJokes'] != null
          ? List<Joke>.from(
              json['componentJokes'].map((j) => Joke.fromJson(j)))
          : [],
      themes: List<String>.from(json['themes'] ?? []),
      shadowElements: List<String>.from(json['shadowElements'] ?? []),
      score: json['score']?.toDouble() ?? 0.0,
      improvements: json['improvements'] != null
          ? Map<String, String>.from(json['improvements'])
          : null,
      contextMetadata: json['contextMetadata'] != null
          ? ContextMetadata.fromJson(json['contextMetadata'])
          : null,
      recordingPath: json['recordingPath'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory Bit.fromJsonString(String jsonString) =>
      Bit.fromJson(jsonDecode(jsonString));
}

class Idea {
  String content;
  double potentialScore;
  String developmentStatus;
  List<String> themes;
  List<String> shadowElements;
  ContextMetadata? contextMetadata;
  String? recordingPath;
  DateTime createdAt;
  bool isFavorite;

  Idea({
    required this.content,
    this.potentialScore = 0.0,
    this.developmentStatus = 'draft',
    List<String>? themes,
    List<String>? shadowElements,
    this.contextMetadata,
    this.recordingPath,
    DateTime? createdAt,
    this.isFavorite = false,
  })  : themes = themes ?? [],
        shadowElements = shadowElements ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'potentialScore': potentialScore,
      'developmentStatus': developmentStatus,
      'themes': themes,
      'shadowElements': shadowElements,
      'contextMetadata': contextMetadata?.toJson(),
      'recordingPath': recordingPath,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory Idea.fromJson(Map<String, dynamic> json) {
    return Idea(
      content: json['content'] ?? '',
      potentialScore: json['potentialScore']?.toDouble() ?? 0.0,
      developmentStatus: json['developmentStatus'] ?? 'draft',
      themes: List<String>.from(json['themes'] ?? []),
      shadowElements: List<String>.from(json['shadowElements'] ?? []),
      contextMetadata: json['contextMetadata'] != null
          ? ContextMetadata.fromJson(json['contextMetadata'])
          : null,
      recordingPath: json['recordingPath'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory Idea.fromJsonString(String jsonString) =>
      Idea.fromJson(jsonDecode(jsonString));
}

class Setlist {
  String title;
  List<dynamic> items; // Can contain Joke or Bit objects
  DateTime createdAt;
  bool isFavorite;

  Setlist({
    required this.title,
    List<dynamic>? items,
    DateTime? createdAt,
    this.isFavorite = false,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'items': items.map((item) {
        if (item is Joke) {
          return {'type': 'joke', 'data': item.toJson()};
        } else if (item is Bit) {
          return {'type': 'bit', 'data': item.toJson()};
        } else {
          throw Exception('Unknown item type in setlist');
        }
      }).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory Setlist.fromJson(Map<String, dynamic> json) {
    List<dynamic> parsedItems = [];
    if (json['items'] != null) {
      for (var item in json['items']) {
        if (item['type'] == 'joke') {
          parsedItems.add(Joke.fromJson(item['data']));
        } else if (item['type'] == 'bit') {
          parsedItems.add(Bit.fromJson(item['data']));
        }
      }
    }

    return Setlist(
      title: json['title'] ?? '',
      items: parsedItems,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory Setlist.fromJsonString(String jsonString) =>
      Setlist.fromJson(jsonDecode(jsonString));
}