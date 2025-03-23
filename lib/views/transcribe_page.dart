// lib/views/transcribe_page.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'categorize_page.dart';
import '../utils/theme.dart';

class TranscribePage extends StatefulWidget {
  final String recordingPath;
  
  const TranscribePage({super.key, required this.recordingPath});

  @override
  State<TranscribePage> createState() => _TranscribePageState();
}

class _TranscribePageState extends State<TranscribePage> {
  final TextEditingController _textController = TextEditingController();
  final player = AudioPlayer();
  bool isPlaying = false;
  bool autoSaveEnabled = false;
  bool isWebRecording = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    isWebRecording = kIsWeb && widget.recordingPath.startsWith('blob:');
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (isWebRecording || widget.recordingPath == 'web_demo_recording.webm') {
        // Web recording detected - set a demo transcription
        debugPrint("Web recording detected - using demo transcription");
        
        _textController.text = 'I was at a restaurant the other day, and I noticed how everyone is taking photos of their food. Remember when we just ate it? Now we have to document it like evidence. "Officer, this waffle was present at my brunch."';
      } else {
        // Attempt to load the audio file
        try {
          await player.setFilePath(widget.recordingPath);
          debugPrint("Audio loaded successfully");
          _textController.text = 'Your transcription will appear here. For now, you can edit this text manually.';
        } catch (e) {
          debugPrint("Error loading audio file: $e");
          // Fallback to demo transcription if audio loading fails
          _textController.text = 'Demo transcription: I was thinking about how weird airplane food is...';
          
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

  void _togglePlayback() async {
    if (isWebRecording) {
      // For web recordings, just simulate playback
      setState(() {
        isPlaying = !isPlaying;
      });
      
      if (isPlaying) {
        // Simulate playing for 3 seconds then automatically stop
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && isPlaying) {
            setState(() {
              isPlaying = false;
            });
          }
        });
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

  @override
  void dispose() {
    _textController.dispose();
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
            colors: [AppTheme.primaryColor.withOpacity(0.05), Colors.white],
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
                    
                    // Text editor section
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Edit transcription here...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Character count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${_textController.text.length} characters',
                        style: TextStyle(
                          fontSize: 12, 
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
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
                            color: Colors.amber.withOpacity(0.1),
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
                                  transcription: _textController.text,
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
}