// lib/views/transcribe_page.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'categorize_page.dart';
import '../utils/theme.dart';
import 'dart:async';
import 'dart:math';

class TranscribePage extends StatefulWidget {
  final String recordingPath;
  
  const TranscribePage({super.key, required this.recordingPath});

  @override
  State<TranscribePage> createState() => _TranscribePageState();
}

class _TranscribePageState extends State<TranscribePage> {
  final player = AudioPlayer();
  bool isPlaying = false;
  bool autoSaveEnabled = false;
  bool isWebRecording = false;
  bool isLoading = true;
  
  // Transcription content
  String _transcription = '';
  List<String> _words = [];
  
  // Word tracking
  int _currentWordIndex = -1;
  List<Duration> _wordTimings = [];
  Duration _currentPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    isWebRecording = kIsWeb && widget.recordingPath.startsWith('blob:');
    _loadAudio();
    _setupWordTimings();
  }

  Future<void> _loadAudio() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (isWebRecording || widget.recordingPath == 'web_demo_recording.webm') {
        // Web recording detected - set a demo transcription
        debugPrint("Web recording detected - using demo transcription");
        
        _setDemoTranscription('I was at a restaurant the other day, and I noticed how everyone is taking photos of their food. Remember when we just ate it? Now we have to document it like evidence. "Officer, this waffle was present at my brunch."');
      } else {
        // Attempt to load the audio file
        try {
          await player.setFilePath(widget.recordingPath);
          debugPrint("Audio loaded successfully");
          
          // In a real implementation, you would call a speech-to-text service
          // For now, we'll use a placeholder transcription
          _setDemoTranscription('Your transcription will appear here. This text is synchronized with the audio playback.');
          
          // Set up position tracking
          _setupPositionTracking();
        } catch (e) {
          debugPrint("Error loading audio file: $e");
          // Fallback to demo transcription if audio loading fails
          _setDemoTranscription('Demo transcription: I was thinking about how weird airplane food is...');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Audio playback unavailable: $e")),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error in _loadAudio: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  
  void _setDemoTranscription(String text) {
    _transcription = text;
    _words = text.split(' ');
  }
  
  void _setupWordTimings() {
    // This would ideally come from a speech-to-text service that provides word timings
    // For now, we're creating synthetic timings for demonstration
    _wordTimings = [];
    
    // Generate synthetic word timings - assume each word takes about 0.3-0.5 seconds
    final random = Random();
    Duration totalDuration = Duration.zero;
    
    for (int i = 0; i < _words.length; i++) {
      // Vary the duration a bit based on word length
      int wordLength = _words[i].length;
      int millisPerWord = 300 + (wordLength * 30) + random.nextInt(200);
      Duration wordDuration = Duration(milliseconds: millisPerWord);
      
      _wordTimings.add(totalDuration);
      totalDuration += wordDuration;
    }
  }
  
  void _setupPositionTracking() {
    // Listen to playback position updates
    _positionSubscription?.cancel();
    _positionSubscription = player.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _updateCurrentWordIndex();
        });
      }
    });
    
    // Listen for playback completion
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            isPlaying = false;
            _currentWordIndex = -1;
          });
        }
      }
    });
  }
  
  void _updateCurrentWordIndex() {
    // Find which word corresponds to the current position
    if (_wordTimings.isEmpty) return;
    
    // Find the last word timing that is less than or equal to current position
    for (int i = _wordTimings.length - 1; i >= 0; i--) {
      if (_currentPosition >= _wordTimings[i]) {
        if (_currentWordIndex != i) {
          setState(() {
            _currentWordIndex = i;
          });
        }
        break;
      }
    }
  }

  void _togglePlayback() async {
    if (isWebRecording) {
      // For web recordings, just simulate playback
      setState(() {
        isPlaying = !isPlaying;
        if (isPlaying) {
          _currentWordIndex = 0;
        } else {
          _currentWordIndex = -1;
        }
      });
      
      if (isPlaying) {
        // Simulate playing with word tracking
        _simulatePlayback();
      }
      
      return;
    }
    
    try {
      if (isPlaying) {
        await player.pause();
      } else {
        await player.play();
      }
      setState(() {
        isPlaying = !isPlaying;
      });
    } catch (e) {
      debugPrint("Error with playback: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error with playback: $e")),
        );
      }
    }
  }
  
  void _simulatePlayback() {
    // Simulate word-by-word playback for web demo
    if (!isPlaying) return;
    
    int totalWords = _words.length;
    int currentWord = 0;
    
    // Use timer to update current word every 300-500ms
    Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted || !isPlaying) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _currentWordIndex = currentWord;
      });
      
      currentWord++;
      
      if (currentWord >= totalWords) {
        setState(() {
          isPlaying = false;
          _currentWordIndex = -1;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcribe'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withAlpha(13),  // 0.05 * 255 ≈ 13
              Colors.white
            ],
          ),
        ),
        child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Audio player card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Play button
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPlaying ? Colors.red : AppTheme.primaryColor,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _togglePlayback,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Recording',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isWebRecording 
                                        ? 'Web recording (demo mode)' 
                                        : widget.recordingPath.split('/').last,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Transcription display section
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildTranscriptionText(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Controls row
                    Row(
                      children: [
                        // Premium toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(26),  // 0.1 * 255 ≈ 26
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber.shade200,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                size: 16,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Auto-save AI:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Switch(
                                value: autoSaveEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    autoSaveEnabled = value;
                                  });
                                  if (value) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Premium feature')),
                                    );
                                    // Reset after showing message
                                    Future.delayed(const Duration(milliseconds: 500), () {
                                      if (mounted) {
                                        setState(() {
                                          autoSaveEnabled = false;
                                        });
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Action buttons
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategorizePage(
                                  transcription: _transcription,
                                  recordingPath: widget.recordingPath,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
  
  Widget _buildTranscriptionText() {
    if (_words.isEmpty) {
      return const Center(child: Text('No transcription available'));
    }
    
    return SingleChildScrollView(
      child: Wrap(
        spacing: 4.0,
        runSpacing: 4.0,
        children: List.generate(_words.length, (index) {
          bool isCurrent = index == _currentWordIndex;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isCurrent ? AppTheme.primaryColor.withAlpha(77) : Colors.transparent,  // 0.3 * 255 ≈ 77
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _words[index],
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? AppTheme.primaryColor : Colors.black87,
              ),
            ),
          );
        }),
      ),
    );
  }
}
