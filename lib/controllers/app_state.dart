// lib/controllers/app_state.dart
import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  int _currentIndex = 0;
  final StorageService _storageService = StorageService();
  
  // Library state
  List<dynamic> _allMaterial = [];
  List<dynamic> _filteredMaterial = [];
  String _searchQuery = '';
  bool _isLoading = false;
  int _libraryTabIndex = 0; // 0: All, 1: Jokes, 2: Bits, 3: Ideas
  
  // Recording state
  String? _lastRecordingPath;
  String? _lastTranscription;
  
  // Getters
  int get currentIndex => _currentIndex;
  List<dynamic> get allMaterial => _allMaterial;
  List<dynamic> get filteredMaterial => _filteredMaterial;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  int get libraryTabIndex => _libraryTabIndex;
  String? get lastRecordingPath => _lastRecordingPath;
  String? get lastTranscription => _lastTranscription;
  
  // Navigation methods
  void updateIndex(int index) {
    _currentIndex = index;
    // If navigating to library, load material
    if (index == 1) {
      loadMaterial();
    }
    notifyListeners();
  }
  
  // Library methods
  Future<void> loadMaterial() async {
    _setLoading(true);
    try {
      _allMaterial = await _storageService.getAllMaterial();
      _filterMaterial();
    } catch (e) {
      debugPrint('Error loading material: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  void updateLibraryTab(int index) {
    _libraryTabIndex = index;
    _filterMaterial();
    notifyListeners();
  }
  
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _filterMaterial();
    notifyListeners();
  }
  
  void _filterMaterial() {
    if (_searchQuery.isEmpty && _libraryTabIndex == 0) {
      _filteredMaterial = List.from(_allMaterial);
    } else {
      // First filter by type based on tab
      List<dynamic> typeFiltered = _allMaterial.where((item) {
        if (_libraryTabIndex == 0) return true;
        if (_libraryTabIndex == 1) return item is Joke;
        if (_libraryTabIndex == 2) return item is Bit;
        if (_libraryTabIndex == 3) return item is Idea;
        return false;
      }).toList();
      
      // Then filter by search query
      if (_searchQuery.isNotEmpty) {
        final lowerQuery = _searchQuery.toLowerCase();
        _filteredMaterial = typeFiltered.where((item) {
          if (item is Joke) {
            return item.setup.toLowerCase().contains(lowerQuery) || 
                  item.punchline.toLowerCase().contains(lowerQuery);
          } else if (item is Bit) {
            return item.title.toLowerCase().contains(lowerQuery) || 
                  item.content.toLowerCase().contains(lowerQuery);
          } else if (item is Idea) {
            return item.content.toLowerCase().contains(lowerQuery);
          }
          return false;
        }).toList();
      } else {
        _filteredMaterial = typeFiltered;
      }
    }
  }
  
  Future<void> toggleFavorite(dynamic item, int index) async {
    await _storageService.toggleFavorite(item, index);
    await loadMaterial();
  }
  
  // Recording/Transcription methods
  void setLastRecordingPath(String path) {
    _lastRecordingPath = path;
    notifyListeners();
  }
  
  void setLastTranscription(String transcription) {
    _lastTranscription = transcription;
    notifyListeners();
  }
  
  // Save content based on category
  Future<void> saveContent({
    required String contentType,
    required String title,
    required String content,
    String? recordingPath,
  }) async {
    _setLoading(true);
    try {
      if (contentType == 'Joke') {
        // Simple heuristic: split content into setup and punchline
        List<String> parts = content.split('\n\n');
        String setup = parts.length > 1 ? parts[0] : content;
        String punchline = parts.length > 1 ? parts[1] : '';
        
        Joke joke = Joke(
          setup: setup,
          punchline: punchline,
          recordingPath: recordingPath,
        );
        await _storageService.saveJoke(joke);
      } else if (contentType == 'Bit') {
        Bit bit = Bit(
          title: title,
          content: content,
          recordingPath: recordingPath,
        );
        await _storageService.saveBit(bit);
      } else if (contentType == 'Idea') {
        Idea idea = Idea(
          content: content,
          recordingPath: recordingPath,
        );
        await _storageService.saveIdea(idea);
      }
      
      // Reload material
      if (_currentIndex == 1) {
        await loadMaterial();
      }
    } catch (e) {
      debugPrint('Error saving content: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}