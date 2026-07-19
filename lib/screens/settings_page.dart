import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../state/workout_state.dart';
import '../widgets/bouncing_widget.dart';

class SettingsPage extends StatefulWidget {
  final WorkoutState appState;

  const SettingsPage({super.key, required this.appState});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  // NEW: Safely launches the user's default email app
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'chathushkapromaxx@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'My Workout App - Support & Feedback',
      }),
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Could not launch email app');
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

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

  void _showFontLicenseDialog(BuildContext context, bool isDark, Color dialogBg, Color textColor, Color subTextColor) {
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
          title: Text('Font License', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              '''FONT LICENSE : Free for personal Use\n\nFONT NAME: RIVERA\nCopyright © [2023] [Shinko Art Studio]\n\nPERMISSION & CONDITIONS\nYou are allowed to:\n• Use the font for personal, academic, or commercial purposes\n• Modify the font to suit your design or language needs\n• Distribute the font with your work or on its own\n• Embed the font in documents, websites, apps, or products\n\nYou must NOT:\n• Sell the font by itself\n• Rename the font when distributing without making it clear it's a derivative\n• Claim authorship of the original font\n\nDISCLAIMER\nTHE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.\nTHE AUTHOR IS NOT LIABLE FOR ANY DAMAGES RESULTING FROM THE USE OF THIS FONT SOFTWARE.''',
              style: TextStyle(color: subTextColor, fontSize: 14, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, child) {
        
        final bool isDark = widget.appState.isDarkMode;
        final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color subTextColor = isDark ? Colors.grey : Colors.grey.shade600;
        final Color cardColor = isDark ? const Color(0xFF141414) : Colors.white;
        final Color dialogBg = isDark ? const Color(0xFF121212) : Colors.white;
        final Color dividerColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
        final Color frostedBg = isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6);

        bool hasProfileImage = widget.appState.profileImagePath != null && File(widget.appState.profileImagePath!).existsSync();
        final double topPadding = MediaQuery.of(context).padding.top + 80.0;

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: topPadding, bottom: 60, left: 20, right: 20),
                  children: [
                    const SizedBox(height: 20),

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
                    
                    // NEW: HELP & SUPPORT SECTION
                    Text('Help & Support', style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
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
                            onTap: () => Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => GuidePage(appState: widget.appState))
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Icon(Icons.menu_book_rounded, color: textColor, size: 24),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('How to use the app', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text('Quick guide to features and gestures', style: TextStyle(color: subTextColor, fontSize: 14)),
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
                            onTap: _launchEmail,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Icon(Icons.mail_rounded, color: textColor, size: 24),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Contact Developer', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text('Report bugs or request features', style: TextStyle(color: subTextColor, fontSize: 14)),
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
                    
                    const SizedBox(height: 35),

                    // ABOUT APP & DEVELOPER SECTION
                    Text('About', style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
                      ),
                      child: Column(
                        children: [
                          
                          // 1. App Info
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.asset(
                                    'assets/app_icon.png', 
                                    width: 60, 
                                    height: 60, 
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 60, height: 60, color: isDark ? Colors.white12 : Colors.black12,
                                      child: Icon(Icons.fitness_center, color: textColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('My Workout', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('Version 1.0.0', style: TextStyle(color: subTextColor, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: dividerColor),
                          
                          // 2. Developer Info
                          BouncingWidget(
                            onTap: () => _launchUrl('https://github.com/chathushkaimasara'),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                    backgroundImage: const NetworkImage('https://github.com/chathushkaimasara.png'),
                                    onBackgroundImageError: (_, __) {}, 
                                    child: const Icon(Icons.person, color: Colors.transparent), 
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Chathushka Imasara', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text('Developer', style: TextStyle(color: subTextColor, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.open_in_new, color: subTextColor, size: 18),
                                ],
                              ),
                            ),
                          ),
                          Divider(height: 1, color: dividerColor),

                          // 3. Support Banners (GitHub & Ko-fi)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: BouncingWidget(
                                    onTap: () => _launchUrl('https://github.com/chathushkaimasara'),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset('assets/github_button.png', fit: BoxFit.fitWidth),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: BouncingWidget(
                                    onTap: () => _launchUrl('https://ko-fi.com/chathushkaimasara#payment-widget'),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset('assets/kofi_button.png', fit: BoxFit.fitWidth),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: dividerColor),

                          // 4. Licenses
                          BouncingWidget(
                            onTap: () => Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => AppLicensesPage(appState: widget.appState))
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Icon(Icons.gavel, color: textColor, size: 24),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Text('App Licenses', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                  ),
                                  Icon(Icons.arrow_forward_ios, color: subTextColor, size: 16),
                                ],
                              ),
                            ),
                          ),
                          Divider(height: 1, color: dividerColor, indent: 60),
                          BouncingWidget(
                            onTap: () => _showFontLicenseDialog(context, isDark, dialogBg, textColor, subTextColor),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Icon(Icons.font_download, color: textColor, size: 24),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Text('Font License', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                  ),
                                  Icon(Icons.arrow_forward_ios, color: subTextColor, size: 16),
                                ],
                              ),
                            ),
                          ),
                          
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),

              // HEADER
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      color: frostedBg, 
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 20, 
                        bottom: 15,
                      ),
                      child: Row(
                        children: [
                          BouncingWidget(
                            onTap: () => Navigator.pop(context),
                            child: CircleAvatar(
                              radius: 20, 
                              backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, 
                              child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18)
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text('Settings', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        );
      },
    );
  }
}


// ---------------------------------------------------------
// NEW: CUSTOM GUIDE PAGE WITH FROSTED GLASS
// ---------------------------------------------------------
class GuidePage extends StatelessWidget {
  final WorkoutState appState;
  const GuidePage({super.key, required this.appState});

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 25.0, bottom: 15.0),
      child: Text(title, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGuideItem(IconData icon, String title, String description, Color textColor, Color subTextColor, Color cardColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(description, style: TextStyle(color: subTextColor, fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = appState.isDarkMode;
    final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey.shade600;
    final Color cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final Color frostedBg = isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6);
    final double topPadding = MediaQuery.of(context).padding.top + 80.0;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(top: topPadding, bottom: 60, left: 20, right: 20),
              children: [
                
                _buildSectionTitle('Workouts & Schedule', textColor),
                _buildGuideItem(Icons.add_box_rounded, 'Adding a Day', 'Tap the big "+" button on the home screen to create a new workout day (e.g., Push Day, Leg Day).', textColor, subTextColor, cardColor, isDark),
                _buildGuideItem(Icons.swipe_rounded, 'Editing a Day', 'Press and hold any workout day card to reveal the hidden menu. From there, you can rename it, add a background picture, pin it to the top, or delete it.', textColor, subTextColor, cardColor, isDark),
                _buildGuideItem(Icons.drag_handle_rounded, 'Reordering', 'Simply hold and drag a workout day card to rearrange your schedule in any order you prefer.', textColor, subTextColor, cardColor, isDark),
                
                _buildSectionTitle('Inside the Gym', textColor),
                _buildGuideItem(Icons.fitness_center_rounded, 'Adding Exercises', 'Tap inside a day, then tap "+" to add exercises and their reps.', textColor, subTextColor, cardColor, isDark),
                _buildGuideItem(Icons.check_circle_rounded, 'Completing Sets', 'Tap the circle icon next to an exercise to mark it as completed while you work out.', textColor, subTextColor, cardColor, isDark),
                _buildGuideItem(Icons.horizontal_rule_rounded, 'Dividers', 'Use the divider button in the popup menu to separate your warmups from your main lifts.', textColor, subTextColor, cardColor, isDark),
                
                _buildSectionTitle('Tracking Progress', textColor),
                _buildGuideItem(Icons.bar_chart_rounded, 'The Progress Page', 'Tap the graph button on the home screen to see your progress. The app automatically groups all exercises by name.', textColor, subTextColor, cardColor, isDark),
                _buildGuideItem(Icons.add_chart_rounded, 'Logging Weight', 'Tap the "+" icon next to an exercise to quickly record your heaviest lift for that day.', textColor, subTextColor, cardColor, isDark),
                _buildGuideItem(Icons.show_chart_rounded, 'Viewing Graphs', 'Tap the line chart icon to see a beautiful graph of how your strength has increased over time.', textColor, subTextColor, cardColor, isDark),
                
              ],
            ),
          ),

          // THE FROSTED GLASS HEADER
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  color: frostedBg, 
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 20, 
                    bottom: 15,
                  ),
                  child: Row(
                    children: [
                      BouncingWidget(
                        onTap: () => Navigator.pop(context),
                        child: CircleAvatar(
                          radius: 20, 
                          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, 
                          child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18)
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text('How to Use', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOM APP LICENSES PAGE WITH FROSTED GLASS
// ---------------------------------------------------------
class AppLicensesPage extends StatefulWidget {
  final WorkoutState appState;
  const AppLicensesPage({super.key, required this.appState});

  @override
  State<AppLicensesPage> createState() => _AppLicensesPageState();
}

class _AppLicensesPageState extends State<AppLicensesPage> {
  List<LicenseEntry> _licenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    final licenses = await LicenseRegistry.licenses.toList();
    if (mounted) {
      setState(() {
        _licenses = licenses;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.appState.isDarkMode;
    final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey.shade600;
    final Color frostedBg = isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6);
    
    final double topPadding = MediaQuery.of(context).padding.top + 80.0;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: textColor))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: topPadding, bottom: 40, left: 20, right: 20),
                  itemCount: _licenses.length,
                  itemBuilder: (context, index) {
                    final entry = _licenses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.packages.join(', '), 
                            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.paragraphs.map((p) => p.text).join('\n\n'), 
                            style: TextStyle(color: subTextColor, fontSize: 13, height: 1.4)
                          ),
                          const SizedBox(height: 15),
                          Divider(color: isDark ? Colors.white24 : Colors.black12),
                        ],
                      ),
                    );
                  },
                ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  color: frostedBg, 
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 20, 
                    bottom: 15,
                  ),
                  child: Row(
                    children: [
                      BouncingWidget(
                        onTap: () => Navigator.pop(context),
                        child: CircleAvatar(
                          radius: 20, 
                          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, 
                          child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18)
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text('App Licenses', style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
