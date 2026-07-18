import 'package:flutter/material.dart';
import '../state/workout_state.dart';
import '../widgets/neumorphic_button.dart';

class SettingsPage extends StatelessWidget {
  final WorkoutState appState;
  const SettingsPage({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w300)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark Mode', style: TextStyle(fontSize: 18)),
                Switch(
                  value: appState.isDarkMode,
                  onChanged: (val) => appState.toggleTheme(),
                  activeColor: Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 50),
            Center(
              child: Column(
                children: [
                  NeumorphicButton(
                    icon: Icons.cloud_download_outlined,
                    label: 'Import Data',
                    isDark: appState.isDarkMode,
                    onTap: () async {
                      await appState.importData();
                      if(context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data Imported Successfully'))
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  NeumorphicButton(
                    icon: Icons.cloud_upload_outlined,
                    label: 'Export Data',
                    isDark: appState.isDarkMode,
                    onTap: () async {
                      await appState.exportData();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
