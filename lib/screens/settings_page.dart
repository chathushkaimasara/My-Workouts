import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../state/workout_state.dart';
import '../widgets/bouncing_widget.dart';

class SettingsPage extends StatefulWidget {
  final WorkoutState appState;

  const SettingsPage({super.key, required this.appState});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  
  Future<void> _pickAndCropProfileImage(bool isDark) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), 
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Profile Picture',
            toolbarColor: isDark ? const Color(0xFF121212) : Colors.white,
            toolbarWidgetColor: isDark ? Colors.white : Colors.black,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle, 
          ),
          IOSUiSettings(
            title: 'Profile Picture',
            aspectRatioLockEnabled: true,
            cropStyle: CropStyle.circle, 
          ),
        ],
      );

      if (croppedFile != null) {
        widget.appState.updateProfileImage(croppedFile.path);
      }
    }
  }

  void _showEditNameDialog(BuildContext context, bool isDark, Color dialogBg, Color textColor) {
    TextEditingController nameController = TextEditingController(text: widget.appState.userName);
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack).value,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          backgroundColor: dialogBg, 
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Name', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameController,
            style: TextStyle(color: textColor),
            cursorColor: textColor,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Your Name',
              hintStyle: const TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade600)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  widget.appState.updateUserName(nameController.text.trim());
                }
                Navigator.pop(context);
              },
              child: Text('Save', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder guarantees immediate UI updates when toggling theme
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, child) {
        
        // --- DYNAMIC LIGHT / DARK THEME VARIABLES ---
        final bool isDark = widget.appState.isDarkMode;
        final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color subTextColor = isDark ? Colors.grey : Colors.grey.shade600;
        final Color cardColor = isDark ? const Color(0xFF141414) : Colors.white;
        final Color dialogBg = isDark ? const Color(0xFF121212) : Colors.white;
        final Color dividerColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

        bool hasProfileImage = widget.appState.profileImagePath != null && File(widget.appState.profileImagePath!).existsSync();

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                // APP BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      BouncingWidget(
                        onTap: () => Navigator.pop(context),
                        child: CircleAvatar(
                          radius: 20, 
                          backgroundColor: cardColor, 
                          child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18)
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text('Settings', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                // PROFILE PICTURE SECTION
                Center(
                  child: Column(
                    children: [
                      BouncingWidget(
                        onTap: () => _pickAndCropProfileImage(isDark),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: cardColor,
                              backgroundImage: hasProfileImage ? FileImage(File(widget.appState.profileImagePath!)) : null,
                              child: !hasProfileImage ? Icon(Icons.person, color: subTextColor, size: 60) : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(color: bgColor, width: 4),
                              ),
                              child: Icon(Icons.camera_alt, color: isDark ? Colors.black : Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      BouncingWidget(
                        onTap: () => _showEditNameDialog(context, isDark, dialogBg, textColor),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.appState.userName, 
                              style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.edit, color: subTextColor, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PREFERENCES SECTION
                        Text('Preferences', style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.dark_mode, color: textColor, size: 24),
                                    const SizedBox(width: 15),
                                    Text('Dark Mode', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                CupertinoSwitch(
                                  value: widget.appState.isDarkMode,
                                  activeColor: isDark ? Colors.white : Colors.black,
                                  trackColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300,
                                  thumbColor: isDark ? Colors.black : Colors.white,
                                  onChanged: (value) => widget.appState.toggleTheme(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        // DATA SECTION
                        Text('Data', style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
                          ),
                          child: Column(
                            children: [
                              BouncingWidget(
                                onTap: () => widget.appState.exportData(),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Icon(Icons.upload, color: textColor, size: 24),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Export Data', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text('Save your workouts to your phone', style: TextStyle(color: subTextColor, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios, color: subTextColor, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                              Divider(height: 1, color: dividerColor, indent: 60),
                              BouncingWidget(
                                onTap: () => widget.appState.importData(),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Icon(Icons.download, color: textColor, size: 24),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Import Data', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text('Restore your previous backups', style: TextStyle(color: subTextColor, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios, color: subTextColor, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
