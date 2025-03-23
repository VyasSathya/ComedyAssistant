// lib/views/settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Recording settings
  double _maxRecordingDuration = 60.0;
  String _recordingQuality = 'Medium';
  
  // Application settings
  bool _darkMode = false;
  bool _autoTranscribe = true;
  
  // Premium status
  bool _isPremium = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxRecordingDuration = prefs.getDouble('maxRecordingDuration') ?? 60.0;
      _recordingQuality = prefs.getString('recordingQuality') ?? 'Medium';
      _darkMode = prefs.getBool('darkMode') ?? false;
      _autoTranscribe = prefs.getBool('autoTranscribe') ?? true;
      _isPremium = prefs.getBool('isPremium') ?? false;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('maxRecordingDuration', _maxRecordingDuration);
    await prefs.setString('recordingQuality', _recordingQuality);
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('autoTranscribe', _autoTranscribe);
    await prefs.setBool('isPremium', _isPremium);
    
    if (!mounted) return;  // Add this check
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }
  
  void _showPremiumInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Features'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unlock premium features:'),
            const SizedBox(height: 8),
            _buildPremiumFeatureItem('Advanced content analysis'),
            _buildPremiumFeatureItem('Unlimited storage'),
            _buildPremiumFeatureItem('Auto-saving AI'),
            _buildPremiumFeatureItem('Performance scoring'),
            _buildPremiumFeatureItem('Ad-free experience'),
            const SizedBox(height: 16),
            const Text(
              'Subscription available:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Monthly: \$4.99/month'),
            const Text('Annual: \$39.99/year (Save 33%)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Placeholder for premium purchase
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium upgrade coming soon')),
              );
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPremiumFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: ListView(
        children: [
          // Account section
          const ListTile(
            title: Text(
              'Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // Premium status
          ListTile(
            leading: Icon(
              _isPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined,
              color: _isPremium ? Colors.amber : null,
            ),
            title: Text(_isPremium ? 'Premium Account' : 'Free Account'),
            subtitle: Text(_isPremium
                ? 'All premium features unlocked'
                : 'Upgrade to unlock all features'),
            trailing: _isPremium
                ? const Icon(Icons.check_circle, color: Colors.green)
                : TextButton(
                    onPressed: _showPremiumInfo,
                    child: const Text('Upgrade'),
                  ),
          ),
          
          const Divider(),
          
          // Recording settings section
          const ListTile(
            title: Text(
              'Recording Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // Max recording duration
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Maximum Recording Duration'),
            subtitle: Text('${_maxRecordingDuration.toInt()} seconds'),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Slider(
              value: _maxRecordingDuration,
              min: 10,
              max: 300,
              divisions: 29,
              label: '${_maxRecordingDuration.toInt()} sec',
              onChanged: (value) {
                setState(() {
                  _maxRecordingDuration = value;
                });
              },
            ),
          ),
          
          // Recording quality
          ListTile(
            leading: const Icon(Icons.high_quality),
            title: const Text('Recording Quality'),
            trailing: DropdownButton<String>(
              value: _recordingQuality,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _recordingQuality = value;
                  });
                }
              },
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
            ),
          ),
          
          const Divider(),
          
          // Application settings section
          const ListTile(
            title: Text(
              'Application Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // Dark mode
          SwitchListTile(
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            secondary: const Icon(Icons.dark_mode),
          ),
          
          // Auto transcribe
          SwitchListTile(
            value: _autoTranscribe,
            onChanged: (value) {
              setState(() {
                _autoTranscribe = value;
              });
            },
            title: const Text('Auto-Transcribe'),
            subtitle: const Text('Automatically transcribe recordings'),
            secondary: const Icon(Icons.text_fields),
          ),
          
          const Divider(),
          
          // About section
          const ListTile(
            title: Text(
              'About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData 
                  ? '${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})'
                  : 'Loading...';
              
              return ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: Text(version),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon')),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy coming soon')),
              );
            },
          ),
          
          const SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }
}

class SetlistPage extends StatelessWidget {  // or StatefulWidget if needed
  const SetlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // Your setlist page content here
    );
  }
}
