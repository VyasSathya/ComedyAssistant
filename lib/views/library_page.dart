// lib/views/library_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_state.dart';
import '../models/data_models.dart';
import '../utils/theme.dart';
import './material_detail_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Register listener for tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        Provider.of<AppState>(context, listen: false)
            .updateLibraryTab(_tabController.index);
      }
    });
    
    // Load material initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).loadMaterial();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Material'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Jokes'),
            Tab(text: 'Bits'),
            Tab(text: 'Ideas'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search your material...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<AppState>(context, listen: false)
                              .updateSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                Provider.of<AppState>(context, listen: false)
                    .updateSearchQuery(value);
              },
            ),
          ),
          
          // Material list
          Expanded(
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                if (appState.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (appState.filteredMaterial.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: appState.filteredMaterial.length,
                  itemBuilder: (context, index) {
                    final item = appState.filteredMaterial[index];
                    return _buildMaterialCard(context, item, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sentiment_dissatisfied,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No material found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Record some comedy material to get started',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<AppState>(context, listen: false).updateIndex(0);
            },
            icon: const Icon(Icons.mic),
            label: const Text('Start Recording'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMaterialCard(BuildContext context, dynamic item, int index) {
    // Determine item type and customize card accordingly
    String title = '';
    String content = '';
    Color bgColor = Colors.white;
    Color textColor = Colors.black;
    IconData icon = Icons.text_snippet;
    double? score;
    bool isFavorite = false;
    
    if (item is Joke) {
      title = '${item.setup.split(' ').take(6).join(' ')}...';
      content = item.punchline;
      bgColor = AppTheme.jokeBackgroundColor.withAlpha(76);  // 0.3 * 255 ≈ 76
      textColor = AppTheme.jokeTextColor;
      icon = Icons.chat_bubble;
      score = item.score;
      isFavorite = item.isFavorite;
    } else if (item is Bit) {
      title = item.title;
      content = item.content.length > 100 
          ? '${item.content.substring(0, 100)}...' 
          : item.content;
      bgColor = AppTheme.bitBackgroundColor.withAlpha(76);
      textColor = AppTheme.bitTextColor;
      icon = Icons.flash_on;
      score = item.score;
      isFavorite = item.isFavorite;
    } else if (item is Idea) {
      title = '${item.content.split(' ').take(6).join(' ')}...';
      content = item.content.length > 100 
          ? '${item.content.substring(0, 100)}...' 
          : item.content;
      bgColor = AppTheme.ideaBackgroundColor.withAlpha(76);
      textColor = AppTheme.ideaTextColor;
      icon = Icons.lightbulb;
      score = item.potentialScore;
      isFavorite = item.isFavorite;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: bgColor,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MaterialDetailPage(
                material: item,
                index: index,  // Add the missing index parameter
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: textColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${score.round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () {
                      Provider.of<AppState>(context, listen: false)
                          .toggleFavorite(item, index);
                    },
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor.withAlpha(204),  // 0.8 * 255 ≈ 204
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.createdAt.toString().substring(0, 16),
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withAlpha(153),  // 0.6 * 255 ≈ 153
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
