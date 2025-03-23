// lib/views/material_detail_page.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/data_models.dart';
import '../utils/theme.dart';
import '../services/analysis_service.dart';

class MaterialDetailPage extends StatefulWidget {
  final dynamic material;
  final int index;
  
  const MaterialDetailPage({
    super.key,
    required this.material,
    required this.index,
  });

  @override
  State<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends State<MaterialDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _editController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final player = AudioPlayer();
  bool isPlaying = false;
  final AnalysisService _analysisService = AnalysisService();
  Map<String, dynamic> _analysisResults = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContentForEditing();
    _loadAudio();
    _generateAnalysis();
  }
  
  void _loadContentForEditing() {
    if (widget.material is Joke) {
      _editController.text = "${widget.material.setup}\n\n${widget.material.punchline}";
      _titleController.text = widget.material.setup.split(' ').take(6).join(' ') + '...';
    } else if (widget.material is Bit) {
      _editController.text = widget.material.content;
      _titleController.text = widget.material.title;
    } else if (widget.material is Idea) {
      _editController.text = widget.material.content;
      _titleController.text = widget.material.content.split(' ').take(6).join(' ') + '...';
    }
  }
  
  Future<void> _loadAudio() async {
    String? recordingPath;
    
    if (widget.material is Joke) {
      recordingPath = widget.material.recordingPath;
    } else if (widget.material is Bit) {
      recordingPath = widget.material.recordingPath;
    } else if (widget.material is Idea) {
      recordingPath = widget.material.recordingPath;
    }
    
    if (recordingPath != null) {
      try {
        await player.setFilePath(recordingPath);
      } catch (e) {
        debugPrint('Error loading audio: $e');
      }
    }
  }
  
  void _generateAnalysis() {
    if (widget.material is Joke) {
      _analysisResults = _analysisService.analyzeJoke(
        widget.material.setup,
        widget.material.punchline,
      );
    } else if (widget.material is Bit) {
      _analysisResults = _analysisService.analyzeBit(
        widget.material.title,
        widget.material.content,
      );
    } else if (widget.material is Idea) {
      _analysisResults = _analysisService.analyzeIdea(widget.material.content);
    }
  }
  
  void _togglePlayback() async {
    try {
      if (isPlaying) {
        await player.pause();
      } else {
        await player.play();
      }
      if (!mounted) return;  // Add this check
      setState(() {
        isPlaying = !isPlaying;
      });
    } catch (e) {
      debugPrint('Error with playback: $e');
      if (!mounted) return;  // Add this check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio playback not available')),
      );
    }
  }
  
  Color _getThemeColor() {
    if (widget.material is Joke) {
      return AppTheme.jokeBackgroundColor;
    } else if (widget.material is Bit) {
      return AppTheme.bitBackgroundColor;
    } else {
      return AppTheme.ideaBackgroundColor;
    }
  }
  
  Color _getThemeTextColor() {
    if (widget.material is Joke) {
      return AppTheme.jokeTextColor;
    } else if (widget.material is Bit) {
      return AppTheme.bitTextColor;
    } else {
      return AppTheme.ideaTextColor;
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _editController.dispose();
    _titleController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    IconData icon = Icons.text_snippet;
    
    if (widget.material is Joke) {
      title = 'Joke';
      icon = Icons.chat_bubble;
    } else if (widget.material is Bit) {
      title = 'Bit';
      icon = Icons.flash_on;
    } else if (widget.material is Idea) {
      title = 'Idea';
      icon = Icons.lightbulb;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.material.isFavorite ? Icons.star : Icons.star_border,
              color: widget.material.isFavorite ? Colors.amber : null,
            ),
            onPressed: () {
              // Toggle favorite - placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favorite toggled')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Edit'),
            Tab(text: 'Versions'),
            Tab(text: 'Analysis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Edit Tab
          _buildEditTab(),
          
          // Versions Tab
          _buildVersionsTab(),
          
          // Analysis Tab
          _buildAnalysisTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Save changes - placeholder
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changes saved')),
          );
        },
        child: const Icon(Icons.save),
      ),
    );
  }
  
  Widget _buildEditTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.material.recordingPath != null) ...[
            Row(
              children: [
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _togglePlayback,
                ),
                const Text('Play Recording'),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const Text('Content:'),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _editController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Edit your material here...',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVersionsTab() {
    // In a real app, this would display version history
    // For now, we'll show a placeholder
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Version History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This feature will track changes to your material',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Version history coming soon')),
              );
            },
            child: const Text('Create New Version'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnalysisTab() {
    Color themeColor = _getThemeColor();
    Color themeTextColor = _getThemeTextColor();
    double score = _analysisResults['score'] ?? 
                  _analysisResults['potentialScore'] ?? 0.0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    '${score.round()}',
                    style: TextStyle(
                      color: themeTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Performance Score',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getScoreDescription(score),
                        style: TextStyle(
                          color: themeTextColor.withAlpha(204),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Themes
          const Text(
            'Themes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getThemeChips(),
          ),
          
          const SizedBox(height: 24),
          
          // Strengths & Weaknesses
          const Text(
            'Analysis',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          
          if (_analysisResults['mechanism'] != null) ...[
            _buildAnalysisItem(
              'Mechanism',
              _analysisResults['mechanism'],
              Icons.category,
            ),
            const SizedBox(height: 12),
          ],
          
          if (_analysisResults['shadowElements'] != null) ...[
            _buildAnalysisItem(
              'Shadow Elements',
              _analysisResults['shadowElements']?.join(', ') ?? '',
              Icons.psychology,
            ),
            const SizedBox(height: 12),
          ],
          
          const SizedBox(height: 24),
          
          // Improvements
          if (_analysisResults['improvements'] != null &&
              (_analysisResults['improvements'] as Map<String, dynamic>).isNotEmpty) ...[
            const Text(
              'Suggested Improvements',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildImprovementItems(),
          ],
        ],
      ),
    );
  }
  
  List<Widget> _getThemeChips() {
    List<String> themes = [];
    if (_analysisResults['themes'] != null) {
      themes = List<String>.from(_analysisResults['themes']);
    }
    
    return themes.map((theme) {
      return Chip(
        label: Text(theme),
        backgroundColor: _getThemeColor(),
        labelStyle: TextStyle(
          color: _getThemeTextColor(),
        ),
      );
    }).toList();
  }
  
  Widget _buildAnalysisItem(String title, String content, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(content),
            ],
          ),
        ),
      ],
    );
  }
  
  List<Widget> _buildImprovementItems() {
    List<Widget> improvements = [];
    Map<String, dynamic> improvementsMap = _analysisResults['improvements'] ?? {};
    
    improvementsMap.forEach((key, value) {
      improvements.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(value ?? ''),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
    
    return improvements;
  }
  
  String _getScoreDescription(double score) {
    if (score >= 90) {
      return 'Excellent - Ready for stage';
    } else if (score >= 80) {
      return 'Very Good - Nearly stage-ready';
    } else if (score >= 70) {
      return 'Good - Needs some polish';
    } else if (score >= 60) {
      return 'Average - Needs work';
    } else {
      return 'Needs significant development';
    }
  }
}
