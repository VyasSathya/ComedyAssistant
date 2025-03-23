// lib/services/analysis_service.dart
import 'dart:math';
// Removed unused import: '../models/data_models.dart'

class AnalysisService {
  // Singleton pattern
  static final AnalysisService _instance = AnalysisService._internal();

  factory AnalysisService() {
    return _instance;
  }

  AnalysisService._internal();

  // Common comedy themes based on uploaded content
  final List<String> _commonThemes = [
    'Parenting',
    'Childhood',
    'Sexual Content',
    'Relationships',
    'Social Norms',
    'Self-awareness',
    'Technology',
    'Gender Dynamics',
    'Modern Life',
    'Aging',
    'Morality',
  ];

  // Common comedy mechanisms
  final List<String> _commonMechanisms = [
    'Misdirection',
    'Exaggeration',
    'Character Voice',
    'Absurd Logic',
    'Self-deprecation',
    'Contrast',
    'Escalation',
    'Callback',
    'Taboo Breaking',
    'Observational',
  ];

  // Analyze joke content and generate metadata
  Map<String, dynamic> analyzeJoke(String setup, String punchline) {
    // In a real app, this would use AI/NLP to analyze the content
    // Here we're using simple logic for demo purposes
    
    // Generate a score based on content length and complexity
    double baseScore = 60.0; // Start with a default score
    baseScore += min((setup.length / 10), 15); // Longer setups up to a point
    baseScore += min((punchline.length / 5), 15); // Good punchlines
    
    // Add some randomness
    baseScore += (Random().nextDouble() * 10);
    
    // Cap the score at 100
    double score = min(baseScore, 100);
    
    // Select random themes and mechanisms that might apply
    List<String> themes = [];
    List<String> shadowElements = [];
    
    // Add 1-3 random themes
    final themeCount = Random().nextInt(2) + 1;
    _commonThemes.shuffle();
    themes = _commonThemes.take(themeCount).toList();
    
    // Add 1-2 random shadow elements
    final shadowCount = Random().nextInt(1) + 1;
    shadowElements = ['Insecurity', 'Anger', 'Fear', 'Confusion', 'Vanity'];
    shadowElements.shuffle();
    shadowElements = shadowElements.take(shadowCount).toList();
    
    // Select a random mechanism
    _commonMechanisms.shuffle();
    String mechanism = _commonMechanisms.first;
    
    // Generate improvement suggestions based on score
    Map<String, String> improvements = {};
    if (score < 80) {
      if (punchline.length < 20) {
        improvements['punchline'] = 'Consider developing a stronger punchline for more impact';
      }
      if (setup.length < 30) {
        improvements['setup'] = 'The setup could use more detail to create tension';
      }
      improvements['general'] = 'Try exploring more unexpected angles on this topic';
    }
    
    return {
      'score': score,
      'mechanism': mechanism,
      'themes': themes,
      'shadowElements': shadowElements,
      'improvements': improvements,
    };
  }

  // Analyze bit content
  Map<String, dynamic> analyzeBit(String title, String content) {
    // Similar approach to joke analysis but with bit-specific adaptations
    double baseScore = 65.0;
    baseScore += min((content.length / 50), 20); // Longer bits have more to work with
    baseScore += (Random().nextDouble() * 15);
    double score = min(baseScore, 100);
    
    // Select random themes
    _commonThemes.shuffle();
    List<String> themes = _commonThemes.take(Random().nextInt(3) + 1).toList();
    
    // Shadow elements
    List<String> shadowElements = ['Vulnerability', 'Shame', 'Absurdity', 'Taboo'];
    shadowElements.shuffle();
    shadowElements = shadowElements.take(Random().nextInt(2) + 1).toList();
    
    // Improvements
    Map<String, String> improvements = {};
    if (score < 85) {
      improvements['structure'] = 'Consider adding more callbacks throughout the bit';
      improvements['pacing'] = 'Look for opportunities to vary the pacing for more impact';
    }
    
    return {
      'score': score,
      'themes': themes,
      'shadowElements': shadowElements,
      'improvements': improvements,
    };
  }

  // Analyze idea content
  Map<String, dynamic> analyzeIdea(String content) {
    // Ideas are evaluated on potential rather than execution
    double potentialScore = 70.0;
    potentialScore += (content.length / 40); // Longer ideas might have more depth
    potentialScore += (Random().nextDouble() * 15);
    double score = min(potentialScore, 100);
    
    // Themes
    _commonThemes.shuffle();
    List<String> themes = _commonThemes.take(Random().nextInt(2) + 1).toList();
    
    // Shadow elements
    List<String> shadowElements = ['Controversy', 'Insight', 'Uniqueness'];
    shadowElements.shuffle();
    shadowElements = shadowElements.take(Random().nextInt(2) + 1).toList();
    
    return {
      'potentialScore': score,
      'developmentStatus': 'draft',
      'themes': themes,
      'shadowElements': shadowElements,
    };
  }

  // Advanced: Extract potential comedy bits from longer text
  List<Map<String, dynamic>> extractComedySegments(String text) {
    // In a real app, this would use NLP/AI to identify comedy segments
    // For now, we'll use a simple heuristic approach
    
    List<Map<String, dynamic>> segments = [];
    
    // Split by paragraphs
    List<String> paragraphs = text.split('\n\n');
    
    // Look for patterns that might indicate jokes or bits
    for (int i = 0; i < paragraphs.length; i++) {
      String current = paragraphs[i];
      
      // If paragraph contains question marks and is followed by a shorter paragraph,
      // it might be a setup/punchline pattern
      if (current.contains('?') && i < paragraphs.length - 1 && 
          paragraphs[i + 1].length < current.length) {
        segments.add({
          'type': 'joke',
          'setup': current,
          'punchline': paragraphs[i + 1],
          'confidence': 0.7 + (Random().nextDouble() * 0.3),
        });
        i++; // Skip the next paragraph as we've used it as punchline
      }
      // If paragraph is quite long, it might be a bit
      else if (current.length > 200) {
        segments.add({
          'type': 'bit',
          'content': current,
          'confidence': 0.6 + (Random().nextDouble() * 0.4),
        });
      }
      // Shorter paragraphs might be ideas
      else if (current.length > 50) {
        segments.add({
          'type': 'idea',
          'content': current,
          'confidence': 0.5 + (Random().nextDouble() * 0.5),
        });
      }
    }
    
    return segments;
  }

  // Get linguistic signature for a piece of content
  // (For identifying patterns in a comedian's style)
  String getLinguisticSignature(String text) {
    // In a real app, this would analyze word choice, sentence structure, etc.
    // For demo purposes, we'll create a simplified version
    
    // Count sentence length
    List<String> sentences = text.split(RegExp(r'[.!?]'));
    double avgSentenceLength = sentences.isEmpty ? 0 : 
        sentences.map((s) => s.trim().split(' ').length).reduce((a, b) => a + b) / sentences.length;
    
    // Count words that might indicate comedy styles
    int absurdWordCount = RegExp(r'\b(crazy|insane|ridiculous|absurd)\b', caseSensitive: false)
        .allMatches(text).length;
    
    int observationalWordCount = RegExp(r'\b(always|never|everyone|people)\b', caseSensitive: false)
        .allMatches(text).length;
    
    int selfDeprecatingWordCount = RegExp(r'\b(I|me|my|myself)\b', caseSensitive: false)
        .allMatches(text).length;
    
    // Create a simple signature
    return 'SL:${avgSentenceLength.toStringAsFixed(1)}_AW:${absurdWordCount}_OW:${observationalWordCount}_SD:$selfDeprecatingWordCount';
  }
}
