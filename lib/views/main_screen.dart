// In lib/views/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:comedy_assistant/controllers/app_state.dart';
import 'package:comedy_assistant/views/record_and_transcribe_page.dart'; 
// import 'package:comedy_assistant/views/record_page.dart';
import 'package:comedy_assistant/views/library_page.dart';
import 'package:comedy_assistant/views/setlist_page.dart';
import 'package:comedy_assistant/views/settings_page.dart' as settings;

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentIndex = appState.currentIndex;
    
    final List<Widget> pages = [
      // Replace RecordPage with RecordAndTranscribePage
      const RecordAndTranscribePage(), // Replace this line
      const LibraryPage(),
      const SetlistPage(),
      const settings.SettingsPage()
    ];
    
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => appState.updateIndex(index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted),
            label: 'Setlists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}