// lib/views/record_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:comedy_assistant/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:comedy_assistant/controllers/app_state.dart';
import 'package:record/record.dart';
import 'package:comedy_assistant/views/transcribe_page.dart';
import 'package:path_provider/path_provider.dart';

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
  String? _recordingPath;
  
  late AudioRecorder _audioRecorder;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
  }

  void toggleRecording() async {
    if (isPreparing) return;
    
    if (!isRecording) {
      setState(() {
        isPreparing = true;
      });
      
      await startRecording();
      
      setState(() {
        isPreparing = false;
      });
    } else {
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
    if (await _audioRecorder.hasPermission()) {
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
        
        _recordingPath = path;
        
        if (_recordingPath == null) {
          throw Exception('Recording path is null');
        }

        await _audioRecorder.start(
          path: _recordingPath!,
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
        );
        
        recordingDuration = 0;
        
        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            recordingDuration++;
          });
        });
        
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
            colors: [
              AppTheme.primaryColor.withAlpha((0.1 * 255).toInt()), 
              Colors.white
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).toInt()),
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
            
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                                ? Colors.red.withAlpha((0.3 * 255).toInt())
                                : AppTheme.primaryColor.withAlpha((0.3 * 255).toInt()),
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
                    
                    ElevatedButton.icon(
                      onPressed: () {
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
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: isRecording ? Colors.red.withAlpha((0.1 * 255).toInt()) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: isRecording 
                            ? Border.all(color: Colors.red.withAlpha((0.3 * 255).toInt()), width: 2)
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
