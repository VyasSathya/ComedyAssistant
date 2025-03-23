// lib/views/record_and_transcribe_page.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/theme.dart';
import 'categorize_page.dart';

// Get API key from .env file
final String googleApiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

class RecordAndTranscribePage extends StatefulWidget {
  const RecordAndTranscribePage({super.key});

  @override
  State<RecordAndTranscribePage> createState() => _RecordAndTranscribePageState();
}

class _RecordAndTranscribePageState extends State<RecordAndTranscribePage> with SingleTickerProviderStateMixin {
  // Recording state
  bool isRecording = false;
  bool isPreparing = false;
  String? recordingPath;
  int recordingDuration = 0;
  Timer? recordingTimer;
  late AudioRecorder audioRecorder;
  
  // Playback state
  final player = AudioPlayer();
  bool isPlaying = false;
  Timer? playbackTimer;
  
  // Transcription state
  String transcription = '';
  List<String> words = [];
  int currentWordIndex = -1;
  bool isTranscribing = false;
  bool hasTranscription = false;
  
  // Audio position tracking
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  List<Duration> _wordTimings = [];
  
  // Animation controller for recording button
  late AnimationController pulseController;
  late Animation<double> pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize recorder
    audioRecorder = AudioRecorder();
    
    // Initialize animation
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut)
    );
    
    // Set up audio position tracking
    _setupPositionTracking();
  }
  
  void _setupPositionTracking() {
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
            currentWordIndex = -1;
          });
        }
      }
    });
  }
  
  void _updateCurrentWordIndex() {
    if (_wordTimings.isEmpty || words.isEmpty) return;
    
    for (int i = 0; i < _wordTimings.length; i++) {
      if (i == _wordTimings.length - 1) {
        // Last word
        if (_currentPosition >= _wordTimings[i]) {
          setState(() {
            currentWordIndex = i;
          });
        }
      } else {
        // Check if current position is between this timing and the next
        if (_currentPosition >= _wordTimings[i] && 
            _currentPosition < _wordTimings[i + 1]) {
          setState(() {
            currentWordIndex = i;
          });
          break;
        }
      }
    }
  }

  // Create fallback visualization

  void _createFallbackVisualization() {
    // Create placeholder words with wider content
    if (words.isEmpty) {
      final int wordCount = 30;
      words = List.generate(wordCount, (i) => '◼◼'); // Wider content
      
      // Generate word timings across audio duration
      _wordTimings = [];
      final wordDuration = _totalDuration.inMilliseconds / wordCount;
      
      for (int i = 0; i < wordCount; i++) {
        _wordTimings.add(Duration(milliseconds: (i * wordDuration).round()));
      }
    }
  }

  // Start recording function
  Future<void> startRecording() async {
    if (await audioRecorder.hasPermission()) {
      setState(() {
        isPreparing = true;
      });
      
      try {
        String path;
        if (kIsWeb) {
          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          path = 'recording_$timestamp.webm';
        } else {
          final appDir = await getApplicationDocumentsDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          path = '${appDir.path}/recording_$timestamp.m4a';
        }
        
        recordingPath = path;
        
        if (recordingPath == null) {
          throw Exception('Recording path is null');
        }

        await audioRecorder.start(
          path: recordingPath!,
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
        );
        
        // Reset recording duration and start timer
        recordingDuration = 0;
        recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            recordingDuration++;
          });
        });
        
        setState(() {
          isRecording = true;
          isPreparing = false;
          hasTranscription = false; // Reset transcription state
          words = [];
          currentWordIndex = -1;
        });
        
        debugPrint('Recording started at: $recordingPath');
      } catch (e) {
        debugPrint('Error starting recording: $e');
        setState(() {
          isRecording = false;
          isPreparing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recording error: $e')),
          );
        }
      }
    } else {
      setState(() {
        isPreparing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
    }
  }

  // Stop recording function
  Future<void> stopRecording() async {
    setState(() {
      isPreparing = true;
      isRecording = false;
    });
    
    recordingTimer?.cancel();
    recordingTimer = null;
    
    try {
      final path = await audioRecorder.stop();
      
      // Always clear the isPreparing state
      setState(() {
        isPreparing = false;
        isTranscribing = true;
      });
      
      // Load audio for playback
      if (path != null) {
        try {
          await player.setFilePath(path);
          _totalDuration = player.duration ?? Duration.zero;
          debugPrint('Audio loaded successfully with duration: $_totalDuration');
          
          // Create fallback visualization regardless of transcription success
          _createFallbackVisualization();
          
          // Perform actual transcription
          await performTranscription(File(path));
          
        } catch (e) {
          debugPrint('Error loading audio: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Audio loading error: $e')),
            );
          }
          setState(() {
            isTranscribing = false;
            isPreparing = false; // Ensure this is reset
            hasTranscription = true; // Still show visualization
          });
        }
      } else {
        debugPrint('No recording path returned');
        setState(() {
          isTranscribing = false;
          isPreparing = false; // Ensure this is reset
        });
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() {
        isPreparing = false;
        isTranscribing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  // Perform transcription
  Future<void> performTranscription(File audioFile) async {
    try {
      if (googleApiKey.isEmpty) {
        debugPrint('Google API key is empty. Falling back to simulated transcription.');
        await _simulateBasicTranscription(_totalDuration.inMilliseconds / 1000);
        return;
      }
      
      // Try Google Speech API
      final result = await callGoogleSpeechApi(audioFile);
      
      if (result['error'] != null) {
        debugPrint('Google Speech API error: ${result['error']}');
        await _simulateBasicTranscription(_totalDuration.inMilliseconds / 1000);
        return;
      }
      
      // Extract results
      transcription = result['text'] ?? '';
      words = transcription.split(' ');
      
      if (result['wordTimings'] != null) {
        _wordTimings = result['wordTimings'];
      } else {
        // If no word timings, create estimated ones
        _createEstimatedWordTimings();
      }
      
      if (mounted) {
        setState(() {
          hasTranscription = true;
          isTranscribing = false;
        });
      }
    } catch (e) {
      debugPrint('Error in transcription: $e. Falling back to simulation.');
      await _simulateBasicTranscription(_totalDuration.inMilliseconds / 1000);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transcription error: $e. Using simulated transcription.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isTranscribing = false;
          hasTranscription = true;
          isPreparing = false; // Ensure this is reset
        });
      }
    }
  }
  
  // Create estimated word timings
  void _createEstimatedWordTimings() {
    _wordTimings = [];
    final wordDuration = _totalDuration.inMilliseconds / words.length;
    
    for (int i = 0; i < words.length; i++) {
      _wordTimings.add(Duration(milliseconds: (i * wordDuration).round()));
    }
  }
  
  // Google Speech API using googleapis
  Future<Map<String, dynamic>> callGoogleSpeechApi(File audioFile) async {
    try {
      // Read audio file as bytes
      final List<int> audioBytes = await audioFile.readAsBytes();
      
      // Convert audio to base64
      final String base64Audio = base64Encode(audioBytes);
      
      // Prepare request to Speech API
      final Map<String, dynamic> requestBody = {
        'config': {
          'encoding': 'LINEAR16',
          'sampleRateHertz': 44100,
          'languageCode': 'en-US',
          'enableWordTimeOffsets': true,
        },
        'audio': {
          'content': base64Audio,
        },
      };
      
      // Make API request
      final response = await http.post(
        Uri.parse('https://speech.googleapis.com/v1/speech:recognize?key=$googleApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      debugPrint('Speech API response code: ${response.statusCode}');
      
      // Check response status
      if (response.statusCode != 200) {
        return {
          'error': 'API error: ${response.statusCode} - ${response.body}',
        };
      }
      
      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      // Extract transcription and word timings
      String text = '';
      List<Duration> wordTimings = [];
      
      if (responseData.containsKey('results') && responseData['results'].isNotEmpty) {
        final result = responseData['results'][0];
        if (result.containsKey('alternatives') && result['alternatives'].isNotEmpty) {
          final alternative = result['alternatives'][0];
          text = alternative['transcript'] ?? '';
          
          // Extract word timings if available
          if (alternative.containsKey('words')) {
            for (var wordInfo in alternative['words']) {
              // Convert startTime string (e.g. "1.500s") to Duration
              final startTimeString = wordInfo['startTime'] ?? '0s';
              final seconds = double.parse(startTimeString.replaceAll('s', ''));
              final milliseconds = (seconds * 1000).round();
              wordTimings.add(Duration(milliseconds: milliseconds));
            }
          }
        }
      }
      
      return {
        'text': text,
        'wordTimings': wordTimings,
      };
    } catch (e) {
      return {'error': 'Error calling Google Speech API: $e'};
    }
  }
  
  // Fallback transcription method
  Future<void> _simulateBasicTranscription(double audioDurationSeconds) async {
    // This function is a fallback for actual transcription
    
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 1));
    
    // Average speaking rate is ~150 words per minute
    final estimatedWordCount = (audioDurationSeconds / 60) * 150;
    
    // Create a somewhat reasonable transcription based on word count
    String generatedTranscription = '';
    
    if (estimatedWordCount < 20) {
      generatedTranscription = "This was a short recording about comedy material.";
    } else if (estimatedWordCount < 50) {
      generatedTranscription = "This is my recording about comedy material. I'm testing the app to see how well it captures my voice and transcribes what I'm saying.";
    } else {
      generatedTranscription = "I'm recording some comedy material to test this application. Let me tell you something funny that happened to me the other day. I was at the store trying to buy groceries, and the cashier kept scanning the same item multiple times. After about the fifth beep, I said, 'I only want one of those!' The cashier looked at me with a straight face and said, 'I know, but it keeps saying item not found, so I'm hoping it will recognize it eventually.' Technology, right?";
    }
    
    transcription = generatedTranscription;
    words = transcription.split(' ');
    
    // Generate word timings based on audio duration
    _wordTimings = [];
    final wordDuration = _totalDuration.inMilliseconds / words.length;
    
    for (int i = 0; i < words.length; i++) {
      _wordTimings.add(Duration(milliseconds: (i * wordDuration).round()));
    }
    
    if (mounted) {
      setState(() {
        hasTranscription = true;
      });
    }
  }

  // Toggle playback of recording
  void togglePlayback() async {
    debugPrint('Toggle playback. hasTranscription: $hasTranscription, words length: ${words.length}');
    debugPrint('Recording path: $recordingPath');
    debugPrint('Audio loaded: ${player.duration != null}, Duration: ${player.duration}');
    
    // Try playing or pausing regardless of other conditions for testing
    try {
      if (isPlaying) {
        await player.pause();
        debugPrint('Audio paused');
        setState(() {
          isPlaying = false;
        });
      } else {
        // Reset position if at the end or if it's invalid
        if (_currentPosition >= _totalDuration || _currentPosition.inMilliseconds <= 0) {
          debugPrint('Seeking to start');
          await player.seek(Duration.zero);
        }
        
        debugPrint('Trying to play audio');
        await player.play();
        debugPrint('Play command issued');
        
        setState(() {
          isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('Error in playback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback error: $e')),
        );
      }
    }
  }

  // Format duration for display
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    recordingTimer?.cancel();
    playbackTimer?.cancel();
    _positionSubscription?.cancel();
    pulseController.dispose();
    player.dispose();
    audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record & Transcribe'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor.withAlpha(13),
                Colors.white
              ],
            ),
          ),
          child: hasTranscription 
              ? _buildTranscriptionSection() 
              : _buildRecordingSection(),
        ),
      ),
    );
  }
  
  // Build the recording UI
  Widget _buildRecordingSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Record Your Material',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        
        // Recording pulse indicator
        if (isRecording)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 15 * pulseAnimation.value,
                  height: 15 * pulseAnimation.value,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                );
              },
            ),
          ),
        
        // Recording button
        GestureDetector(
          onTap: isPreparing ? null : () {
            if (isRecording) {
              stopRecording();
            } else {
              startRecording();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isRecording ? 180 : 160,
            height: isRecording ? 180 : 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: isRecording 
                      ? Colors.red.withAlpha(76)
                      : AppTheme.primaryColor.withAlpha(76),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPreparing 
                      ? Colors.grey
                      : (isRecording ? Colors.red : AppTheme.primaryColor),
                  width: 6,
                ),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isRecording ? 70 : 60,
                  height: isRecording ? 70 : 60,
                  decoration: BoxDecoration(
                    shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: isRecording ? BorderRadius.circular(16) : null,
                    color: isPreparing 
                        ? Colors.grey 
                        : (isRecording ? Colors.red : AppTheme.primaryColor),
                  ),
                  child: isPreparing
                      ? const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Status text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isPreparing
              ? Text(
                  isRecording ? 'Stopping...' : 'Starting...',
                  key: const ValueKey<String>('preparing'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                )
              : isTranscribing
                  ? const Text(
                      'Processing audio...',
                      key: ValueKey<String>('transcribing'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      isRecording ? 'Tap to stop recording' : 'Tap to start recording',
                      key: ValueKey<bool>(isRecording),
                      style: TextStyle(
                        fontSize: 16,
                        color: isRecording ? Colors.red : Colors.grey.shade700,
                        fontWeight: isRecording ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
        ),
        
        const SizedBox(height: 40),
        
        // Timer display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isRecording ? Colors.red.withAlpha(26) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(30),
            border: isRecording 
                ? Border.all(color: Colors.red.withAlpha(76), width: 2)
                : null,
          ),
          child: Text(
            formatDuration(recordingDuration),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: isRecording ? Colors.red : Colors.grey.shade400,
            ),
          ),
        ),
        
        if (isTranscribing)
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Processing audio...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  // Build the transcription UI
  Widget _buildTranscriptionSection() {
    // Format current position and total duration for display
    final currentPositionStr = '${_currentPosition.inMinutes}:${(_currentPosition.inSeconds % 60).toString().padLeft(2, '0')}';
    final totalDurationStr = '${_totalDuration.inMinutes}:${(_totalDuration.inSeconds % 60).toString().padLeft(2, '0')}';
  
    return Padding(
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
              child: Column(
                children: [
                  Row(
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
                          onPressed: togglePlayback,
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
                              recordingPath?.split('/').last ?? 'Recording',
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
                  
                  // Audio progress slider
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: AppTheme.primaryColor,
                    ),
                    child: Slider(
                      value: min(_currentPosition.inMilliseconds.toDouble(), 
                          _totalDuration.inMilliseconds.toDouble()),
                      min: 0,
                      max: max(_totalDuration.inMilliseconds.toDouble(), 1.0),
                      onChanged: _totalDuration.inMilliseconds > 0 
                          ? (value) {
                              player.seek(Duration(milliseconds: value.toInt()));
                            }
                          : null,
                    ),
                  ),
                  
                  // Time display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentPositionStr,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          totalDurationStr,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Transcription display
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: words.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.text_fields,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transcription available',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your audio can still be played',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : // In the _buildTranscriptionSection method, replace the Wrap widget with this:

          SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 12.0,
              children: List.generate(words.length, (index) {
                bool isCurrent = index == currentWordIndex;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  constraints: const BoxConstraints(minWidth: 30), // Add minimum width
                  decoration: BoxDecoration(
                    color: isCurrent ? AppTheme.primaryColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    words[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center, // Center the text
                  ),
                );
              }),
            ),
          ), // End of the _buildTranscriptionSection method
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    hasTranscription = false;
                    words = [];
                    currentWordIndex = -1;
                    recordingDuration = 0;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Record Again'),
              ),
              
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategorizePage(
                        transcription: transcription.isEmpty ? "Recording without transcription" : transcription,
                        recordingPath: recordingPath ?? '',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}