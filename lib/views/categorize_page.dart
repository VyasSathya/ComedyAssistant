// lib/views/categorize_page.dart
import 'package:flutter/material.dart';
import 'package:comedy_assistant/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:comedy_assistant/controllers/app_state.dart';
import 'package:comedy_assistant/services/analysis_service.dart';

class CategorizePage extends StatefulWidget {
  final String transcription;
  final String recordingPath;
  
  const CategorizePage({
    super.key, 
    required this.transcription, 
    required this.recordingPath,
  });

  @override
  State<CategorizePage> createState() => _CategorizePageState();
}

class _CategorizePageState extends State<CategorizePage> {
  String? selectedCategory;
  final TextEditingController _titleController = TextEditingController();
  final AnalysisService _analysisService = AnalysisService();
  bool _isAnalyzing = false;
  Map<String, dynamic> _analysisResults = {};
  
  @override
  void initState() {
    super.initState();
    // Generate a default title based on first few words of content
    final words = widget.transcription.split(' ');
    final titleWords = words.length > 5 ? words.sublist(0, 5) : words;
    _titleController.text = '${titleWords.join(' ')}...';
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  
  void _analyzeContent() {
    setState(() {
      _isAnalyzing = true;
    });
    
    // Run analysis based on selected category
    Future.delayed(const Duration(milliseconds: 800), () {
      if (selectedCategory == 'Joke') {
        // Simple heuristic: split content into setup and punchline
        List<String> parts = widget.transcription.split('\n\n');
        String setup = parts.length > 1 ? parts[0] : widget.transcription;
        String punchline = parts.length > 1 ? parts[1] : '';
        
        _analysisResults = _analysisService.analyzeJoke(setup, punchline);
      } else if (selectedCategory == 'Bit') {
        _analysisResults = _analysisService.analyzeBit(
          _titleController.text, 
          widget.transcription
        );
      } else if (selectedCategory == 'Idea') {
        _analysisResults = _analysisService.analyzeIdea(widget.transcription);
      }
      
      setState(() {
        _isAnalyzing = false;
      });
      
      // Show analysis results
      _showAnalysisResults();
    });
  }
  
  void _showAnalysisResults() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${selectedCategory} Analysis',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Score section
              Row(
                children: [
                  const Text('Performance Score:'),
                  const SizedBox(width: 8),
                  Text(
                    '${_analysisResults['score']?.toStringAsFixed(1) ?? _analysisResults['potentialScore']?.toStringAsFixed(1) ?? '?'}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(_analysisResults['score'] ?? _analysisResults['potentialScore'] ?? 0),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Themes
              const Text(
                'Themes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._getThemeChips(),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Other details specific to the type
              if (selectedCategory == 'Joke' && _analysisResults['mechanism'] != null) ...[
                Text('Mechanism: ${_analysisResults['mechanism']}'),
                const SizedBox(height: 8),
              ],
              
              // Shadow elements
              if (_analysisResults['shadowElements'] != null) ...[
                const Text(
                  'Shadow Elements:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_analysisResults['shadowElements']?.join(', ') ?? ''),
                const SizedBox(height: 16),
              ],
              
              // Improvements section
              if (_analysisResults['improvements'] != null) ...[
                const Text(
                  'Suggested Improvements:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: (_analysisResults['improvements'] as Map<String, dynamic>).length,
                    itemBuilder: (context, index) {
                      final key = (_analysisResults['improvements'] as Map<String, dynamic>).keys.elementAt(index);
                      final value = (_analysisResults['improvements'] as Map<String, dynamic>)[key];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(value ?? ''),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Text('No specific improvements suggested at this time.'),
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
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
  
  Color _getThemeColor() {
    if (selectedCategory == 'Joke') {
      return AppTheme.jokeBackgroundColor;
    } else if (selectedCategory == 'Bit') {
      return AppTheme.bitBackgroundColor;
    } else {
      return AppTheme.ideaBackgroundColor;
    }
  }
  
  Color _getThemeTextColor() {
    if (selectedCategory == 'Joke') {
      return AppTheme.jokeTextColor;
    } else if (selectedCategory == 'Bit') {
      return AppTheme.bitTextColor;
    } else {
      return AppTheme.ideaTextColor;
    }
  }
  
  Color _getScoreColor(double score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorize'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (selectedCategory != null)
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: _isAnalyzing ? null : _analyzeContent,
              tooltip: 'Analyze Content',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Category selection
            const Text(
              'Select Category:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 16),
            
            // Category buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryButton('Joke', AppTheme.jokeBackgroundColor, AppTheme.jokeTextColor, Icons.chat_bubble),
                _buildCategoryButton('Bit', AppTheme.bitBackgroundColor, AppTheme.bitTextColor, Icons.flash_on),
                _buildCategoryButton('Idea', AppTheme.ideaBackgroundColor, AppTheme.ideaTextColor, Icons.lightbulb),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Content preview
            const Text(
              'Content Preview:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 8),
            
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.transcription,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Analysis button
            if (selectedCategory != null && !_isAnalyzing)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: _analyzeContent,
                    icon: const Icon(Icons.psychology),
                    label: const Text('Analyze Content'),
                  ),
                ),
              )
            else if (_isAnalyzing)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedCategory == null 
                    ? null 
                    : () {
                        // Save to storage via app state
                        final appState = Provider.of<AppState>(context, listen: false);
                        appState.saveContent(
                          contentType: selectedCategory!,
                          title: _titleController.text,
                          content: widget.transcription,
                          recordingPath: widget.recordingPath,
                        );
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to My Material')),
                        );
                        
                        // Navigate to library
                        appState.updateIndex(1);
                        
                        // Pop all pages back to main screen
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save to My Material'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryButton(String category, Color bgColor, Color textColor, IconData icon) {
    final isSelected = selectedCategory == category;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.transparent,
          border: Border.all(color: textColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: textColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}