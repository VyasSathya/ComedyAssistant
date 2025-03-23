// lib/services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';

class StorageService {
  // Keys for SharedPreferences
  static const String _jokesKey = 'jokes';
  static const String _bitsKey = 'bits';
  static const String _ideasKey = 'ideas';
  static const String _setlistsKey = 'setlists';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  // --- Jokes Storage ---
  Future<List<Joke>> getJokes() async {
    final prefs = await SharedPreferences.getInstance();
    final jokesJson = prefs.getStringList(_jokesKey) ?? [];
    return jokesJson.map((json) => Joke.fromJsonString(json)).toList();
  }

  Future<void> saveJoke(Joke joke) async {
    final prefs = await SharedPreferences.getInstance();
    final jokes = await getJokes();
    jokes.add(joke);
    await prefs.setStringList(
        _jokesKey, jokes.map((joke) => joke.toJsonString()).toList());
  }

  Future<void> updateJoke(Joke updatedJoke, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final jokes = await getJokes();
    if (index >= 0 && index < jokes.length) {
      jokes[index] = updatedJoke;
      await prefs.setStringList(
          _jokesKey, jokes.map((joke) => joke.toJsonString()).toList());
    }
  }

  Future<void> deleteJoke(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final jokes = await getJokes();
    if (index >= 0 && index < jokes.length) {
      jokes.removeAt(index);
      await prefs.setStringList(
          _jokesKey, jokes.map((joke) => joke.toJsonString()).toList());
    }
  }

  // --- Bits Storage ---
  Future<List<Bit>> getBits() async {
    final prefs = await SharedPreferences.getInstance();
    final bitsJson = prefs.getStringList(_bitsKey) ?? [];
    return bitsJson.map((json) => Bit.fromJsonString(json)).toList();
  }

  Future<void> saveBit(Bit bit) async {
    final prefs = await SharedPreferences.getInstance();
    final bits = await getBits();
    bits.add(bit);
    await prefs.setStringList(
        _bitsKey, bits.map((bit) => bit.toJsonString()).toList());
  }

  Future<void> updateBit(Bit updatedBit, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final bits = await getBits();
    if (index >= 0 && index < bits.length) {
      bits[index] = updatedBit;
      await prefs.setStringList(
          _bitsKey, bits.map((bit) => bit.toJsonString()).toList());
    }
  }

  Future<void> deleteBit(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final bits = await getBits();
    if (index >= 0 && index < bits.length) {
      bits.removeAt(index);
      await prefs.setStringList(
          _bitsKey, bits.map((bit) => bit.toJsonString()).toList());
    }
  }

  // --- Ideas Storage ---
  Future<List<Idea>> getIdeas() async {
    final prefs = await SharedPreferences.getInstance();
    final ideasJson = prefs.getStringList(_ideasKey) ?? [];
    return ideasJson.map((json) => Idea.fromJsonString(json)).toList();
  }

  Future<void> saveIdea(Idea idea) async {
    final prefs = await SharedPreferences.getInstance();
    final ideas = await getIdeas();
    ideas.add(idea);
    await prefs.setStringList(
        _ideasKey, ideas.map((idea) => idea.toJsonString()).toList());
  }

  Future<void> updateIdea(Idea updatedIdea, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final ideas = await getIdeas();
    if (index >= 0 && index < ideas.length) {
      ideas[index] = updatedIdea;
      await prefs.setStringList(
          _ideasKey, ideas.map((idea) => idea.toJsonString()).toList());
    }
  }

  Future<void> deleteIdea(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final ideas = await getIdeas();
    if (index >= 0 && index < ideas.length) {
      ideas.removeAt(index);
      await prefs.setStringList(
          _ideasKey, ideas.map((idea) => idea.toJsonString()).toList());
    }
  }

  // --- Setlists Storage ---
  Future<List<Setlist>> getSetlists() async {
    final prefs = await SharedPreferences.getInstance();
    final setlistsJson = prefs.getStringList(_setlistsKey) ?? [];
    return setlistsJson.map((json) => Setlist.fromJsonString(json)).toList();
  }

  Future<void> saveSetlist(Setlist setlist) async {
    final prefs = await SharedPreferences.getInstance();
    final setlists = await getSetlists();
    setlists.add(setlist);
    await prefs.setStringList(_setlistsKey,
        setlists.map((setlist) => setlist.toJsonString()).toList());
  }

  Future<void> updateSetlist(Setlist updatedSetlist, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final setlists = await getSetlists();
    if (index >= 0 && index < setlists.length) {
      setlists[index] = updatedSetlist;
      await prefs.setStringList(_setlistsKey,
          setlists.map((setlist) => setlist.toJsonString()).toList());
    }
  }

  Future<void> deleteSetlist(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final setlists = await getSetlists();
    if (index >= 0 && index < setlists.length) {
      setlists.removeAt(index);
      await prefs.setStringList(_setlistsKey,
          setlists.map((setlist) => setlist.toJsonString()).toList());
    }
  }

  // --- Combined Material Access (for Library) ---
  Future<List<dynamic>> getAllMaterial() async {
    final jokes = await getJokes();
    final bits = await getBits();
    final ideas = await getIdeas();
    
    // Combine and sort by creation date (newest first)
    List<dynamic> allMaterial = [...jokes, ...bits, ...ideas];
    allMaterial.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return allMaterial;
  }
  
  // --- Search functionality ---
  Future<List<dynamic>> searchMaterial(String query) async {
    if (query.isEmpty) return getAllMaterial();
    
    final allMaterial = await getAllMaterial();
    final lowerQuery = query.toLowerCase();
    
    return allMaterial.where((item) {
      if (item is Joke) {
        return item.setup.toLowerCase().contains(lowerQuery) || 
               item.punchline.toLowerCase().contains(lowerQuery) ||
               item.themes.any((theme) => theme.toLowerCase().contains(lowerQuery));
      } else if (item is Bit) {
        return item.title.toLowerCase().contains(lowerQuery) || 
               item.content.toLowerCase().contains(lowerQuery) ||
               item.themes.any((theme) => theme.toLowerCase().contains(lowerQuery));
      } else if (item is Idea) {
        return item.content.toLowerCase().contains(lowerQuery) ||
               item.themes.any((theme) => theme.toLowerCase().contains(lowerQuery));
      }
      return false;
    }).toList();
  }
  
  // --- Toggle favorite status ---
  Future<void> toggleFavorite(dynamic item, int index) async {
    if (item is Joke) {
      final jokes = await getJokes();
      if (index >= 0 && index < jokes.length) {
        jokes[index].isFavorite = !jokes[index].isFavorite;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
            _jokesKey, jokes.map((joke) => joke.toJsonString()).toList());
      }
    } else if (item is Bit) {
      final bits = await getBits();
      if (index >= 0 && index < bits.length) {
        bits[index].isFavorite = !bits[index].isFavorite;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
            _bitsKey, bits.map((bit) => bit.toJsonString()).toList());
      }
    } else if (item is Idea) {
      final ideas = await getIdeas();
      if (index >= 0 && index < ideas.length) {
        ideas[index].isFavorite = !ideas[index].isFavorite;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
            _ideasKey, ideas.map((idea) => idea.toJsonString()).toList());
      }
    } else if (item is Setlist) {
      final setlists = await getSetlists();
      if (index >= 0 && index < setlists.length) {
        setlists[index].isFavorite = !setlists[index].isFavorite;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_setlistsKey,
            setlists.map((setlist) => setlist.toJsonString()).toList());
      }
    }
  }
}
