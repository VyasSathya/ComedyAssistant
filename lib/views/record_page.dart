// lib/views/record_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:comedy_assistant/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:comedy_assistant/controllers/app_state.dart';
import 'package:record/record.dart';
import 'package:comedy_assistant/views/transcribe_page.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> with SingleTickerProviderStateMixin {
  bool isRecording = false;
  bool isPreparing = false;
  int recordingDuration = 0;
  Timer? timer;
  Timer? pulseTimer;
  double pulseScale = 1.0;
  final _audioRecorder = Record();
  String? _recordingPath;
  
  // Animation controller for the recording indicator pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
  }

  void toggleRecording() async {
    if (isPreparing) return; // Prevent multiple taps during preparation
    
    if (!isRecording) {
      // Starting recording
      setState(() {
        isPreparing = true;
      });
      
      await startRecording();
      
      setState(() {
        isPreparing = false;
      });
    } else {
      // Stopping recording
      setState(() {
        isPreparing = true;
        isRecording = false;
      });
      
      await stopRecording();
      
      setState(() {
        isPreparing = false;
      });
    }
  }

  Future<void> startRecording() async {
    // Check and request permissions
    if (await _audioRecorder.hasPermission()) {
      try {
        // Web or non-web handling for path
        String path;
        if (kIsWeb) {
          // For web, we just use a simple path string 
          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          path = 'recording_$timestamp.webm';
        } else {
          // For mobile
          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          path = 'recording_$timestamp.m4a';
        }
        
        _recordingPath = path;
        
        // Start recording with web-compatible settings
        await _audioRecorder.start(
          path: _recordingPath,
          encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );
        
        // Reset timer
        recordingDuration = 0;
        
        // Start timer for UI
        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            recordingDuration++;
          });
        });
        
        // Update UI state
        setState(() {
          isRecording = true;
        });
        
        debugPrint('Recording started at: $_recordingPath');
      } catch (e) {
        debugPrint('Error starting recording: $e');
        setState(() {
          isRecording = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recording error: $e')),
          );
        }
      }
    } else {
      // Handle permission denied
      setState(() {
        isRecording = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
    }
  }

  Future<void> stopRecording() async {
    timer?.cancel();
    timer = null;
    
    try {
      final path = await _audioRecorder.stop();
      
      if (path != null && mounted) {
        debugPrint('Recording stopped at: $path');
        
        // Navigate to transcribe page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TranscribePage(recordingPath: path),
          ),
        );
        
        setState(() {
          recordingDuration = 0;
        });
      } else {
        if (mounted) {
          if (kIsWeb) {
            debugPrint('Web demo mode - simulating successful recording');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TranscribePage(
                  recordingPath: 'web_demo_recording.webm',
                ),
              ),
            );
            
            setState(() {
              recordingDuration = 0;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to save recording")),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        // Try to continue with a demo recording even if there's an error
        if (kIsWeb) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TranscribePage(
                recordingPath: 'web_demo_recording.webm',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error stopping recording: $e")),
          );
        }
      }
    }
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer?.cancel();
    pulseTimer?.cancel();
    _pulseController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comedy Assistant'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Recording title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Record Your Material',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            
            // Main recording button area
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Recording indicator (visible only when recording)
                    if (isRecording)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 15 * _pulseAnimation.value,
                              height: 15 * _pulseAnimation.value,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                            );
                          },
                        ),
                      ),
                    
                    // Record button with animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isRecording ? 180 : 160,
                      height: isRecording ? 180 : 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: isRecording 
                                ? Colors.red.withOpacity(0.3) 
                                : AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: isPreparing ? null : toggleRecording,
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
                    
                    // Helper text
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
                    
                    // Previous recordings button
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to library page
                        Provider.of<AppState>(context, listen: false).updateIndex(1);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      icon: const Icon(Icons.bookmark),
                      label: const Text(
                        'View previous recordings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Timer display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: isRecording ? Colors.red.withOpacity(0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: isRecording 
                            ? Border.all(color: Colors.red.withOpacity(0.3), width: 2)
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
                    
                    if (isRecording)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mic, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Recording in progress...',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}