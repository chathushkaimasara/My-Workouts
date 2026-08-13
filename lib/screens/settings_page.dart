import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:package_info_plus/package_info_plus.dart'; 
import '../state/workout_state.dart';
import '../widgets/bouncing_widget.dart';
import 'theme_selection_page.dart';

class SettingsPage extends StatefulWidget {
  final WorkoutState appState;

  const SettingsPage({super.key, required this.appState});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'Version ${packageInfo.version}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _appVersion = 'Version 2.0.0');
    }
  }
  
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

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
    
    if (image != null && mounted) {
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

      if (croppedFile != null && mounted) {
        widget.appState.updateProfileImage(croppedFile.path);
      }
    }
  }

  void _showEditNameDialog(BuildContext context, bool isDark, Color dialogBg, Color textColor, Color hintColor, Color underlineColor) {
    final TextEditingController nameController = TextEditingController(text: widget.appState.userName);
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
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
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
              hintStyle: TextStyle(color: hintColor),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: underlineColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(dialogContext);
              },
              child: Text('Cancel', style: TextStyle(color: hintColor)),
            ),
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                if (nameController.text.trim().isNotEmpty) {
                  widget.appState.updateUserName(nameController.text.trim());
                }
                Navigator.pop(dialogContext);
              },
              child: Text('Save', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        nameController.dispose();
      });
    });
  }

  void _showFontLicenseDialog(BuildContext context, Color dialogBg, Color textColor, Color subTextColor) {
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
          content: SizedBox(
            width: double.maxFinite, 
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                _getApacheLicenseText(),
                style: TextStyle(color: subTextColor, fontSize: 13, height: 1.4),
              ),
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

  String _getApacheLicenseText() {
    return '''FONT NAME: Permanent Marker\nDesigned by Font Diner\n\n''' + r'''Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [2026] [Font Diner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.''';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, child) {
        
        final bool isDark = widget.appState.isDarkMode;
        final bool useMaterialYou = widget.appState.useMaterialYou;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        
        final bool isPremiumBlack = !useMaterialYou && widget.appState.themePresetId == 'default_black';

        final Color bgColor = isPremiumBlack ? (isDark ? Colors.black : const Color(0xFFF2F2F7)) : scheme.surface;
        final Color textColor = isPremiumBlack ? (isDark ? Colors.white : Colors.black) : scheme.onSurface;
        final Color subTextColor = isPremiumBlack ? (isDark ? Colors.grey : Colors.grey.shade600) : scheme.onSurfaceVariant;
        final Color cardColor = isPremiumBlack ? (isDark ? const Color(0xFF141414) : Colors.white) : scheme.surfaceContainer;
        final Color dialogBg = isPremiumBlack ? (isDark ? const Color(0xFF121212) : Colors.white) : scheme.surfaceContainerHigh;
        final Color dividerColor = isPremiumBlack ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)) : scheme.outlineVariant.withOpacity(0.5);
        final Color frostedBg = isPremiumBlack ? (isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6)) : scheme.surface.withOpacity(isDark ? 0.8 : 0.7);

        final Color activeToggleColor = isPremiumBlack ? (isDark ? Colors.white : Colors.black) : scheme.primary;
        final Color activeThumbColor = isPremiumBlack ? (isDark ? Colors.black : Colors.white) : scheme.onPrimary;
        final Color inactiveTrackColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300;

        bool hasProfileImage = widget.appState.profileImagePath != null && widget.appState.profileImagePath!.isNotEmpty;
        final double topPadding = MediaQuery.of(context).padding.top + 80.0;

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: topPadding, bottom: 40, left: 20, right: 20),
                  children: [
                    const SizedBox(height: 20),

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
                                  backgroundImage: hasProfileImage 
                                    ? ResizeImage(FileImage(File(widget.appState.profileImagePath!)), width: 250) 
                                    : null,
                                  child: !hasProfileImage ? Icon(Icons.person, color: subTextColor, size: 60) : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isPremiumBlack ? (isDark ? Colors.white : Colors.black) : scheme.primaryContainer,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: bgColor, width: 4),
                                  ),
                                  child: Icon(Icons.camera_alt, color: isPremiumBlack ? (isDark ? Colors.black : Colors.white) : scheme.onPrimaryContainer, size: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          BouncingWidget(
                            onTap: () => _showEditNameDialog(context, isDark, dialogBg, textColor, subTextColor, dividerColor),
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

                    Text('Preferences', style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: !isDark && isPremiumBlack ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
                      ),
                      child: Column(
                        children: [
                          Padding(
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
                                  activeColor: activeToggleColor,
                                  thumbColor: activeThumbColor,
                                  trackColor: inactiveTrackColor,
                                  onChanged: (value) => widget.appState.toggleTheme(),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: dividerColor, indent: 60),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.color_lens, color: textColor, size: 24),
                                    const SizedBox(width: 15),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Material You', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                        Text('Use system wallpaper colors', style: TextStyle(color: subTextColor, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                                CupertinoSwitch(
                                  value: useMaterialYou,
                                  activeColor: activeToggleColor,
                                  thumbColor: activeThumbColor,
                                  trackColor: inactiveTrackColor,
                                  onChanged: (value) => widget.appState.toggleMaterialYou(),
                                ),
                              ],
                            ),
                          ),
                          
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: !useMaterialYou 
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(height: 1, color: dividerColor, indent: 60),
                                    BouncingWidget(
                                      onTap: () => Navigator.push(
                                        context, 
                                        MaterialPageRoute(builder: (context) => ThemeSelectionPage(appState: widget.appState))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                        child: Row(
                                          children: [
                                            Icon(Icons.palette, color: textColor, size: 24),
                                            const SizedBox(width: 15),
                                            Text('Theme Presets', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      appThemePresets.firstWhere((p) => p.id == widget.appState.themePresetId).name, 
                                                      style: TextStyle(color: subTextColor, fontSize: 14),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(Icons.arrow_forward_ios, color: subTextColor, size: 16),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),
                    
                    // HOMESCREEN WIDGET SETTINGS
                    Text('Homescreen', style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: !isDark && isPremiumBlack ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.format_quote, color: textColor, size: 24),
                                    const SizedBox(width: 15),
                                    Text('Motivational Quote', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                CupertinoSwitch(
                                  value: widget.appState.showQuote,
                                  activeColor: activeToggleColor,
                                  thumbColor: activeThumbColor,
                                  trackColor: inactiveTrackColor,
                                  onChanged: (_) => widget.appState.toggleQuote(),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: dividerColor, indent: 60),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month, color: textColor, size: 24),
                                    const SizedBox(width: 15),
                                    Text('Calendar', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                CupertinoSwitch(
                                  value: widget.appState.showCalendar,
                                  activeColor: activeToggleColor,
                                  thumbColor: activeThumbColor,
                                  trackColor: inactiveTrackColor,
                                  onChanged: (_) => widget.appState.toggleCalendar(),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: dividerColor, indent: 60),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.timer_outlined, color: textColor, size: 24),
                                    const SizedBox(width: 15),
                                    Text('Rest Timer', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                CupertinoSwitch(
                                  value: widget.appState.showTimer,
                                  activeColor: activeToggleColor,
                                  thumbColor: activeThumbColor,
                                  trackColor: inactiveTrackColor,
                                  onChanged: (_) => widget.appState.toggleTimer(),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: dividerColor),

                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hold and drag sliders to reposition:', style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 15),
                                SizedBox(
                                  height: 160,
                                  child: ReorderableListView(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, child: child),
                                    onReorder: (oldIndex, newIndex) => widget.appState.reorderHomeWidgets(oldIndex, newIndex),
                                    children: widget.appState.homeWidgetOrder.map((item) {
                                      String title = item == 'quote' ? 'Motivational Quote' : (item == 'calendar' ? 'Calendar' : 'Rest Timer');
                                      IconData icon = item == 'quote' ? Icons.format_quote : (item == 'calendar' ? Icons.calendar_month : Icons.timer_outlined);
                                      return ListTile(
                                        key: ValueKey(item),
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(icon, color: textColor.withOpacity(0.5)),
                                        title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                                        trailing: Icon(Icons.drag_indicator, color: subTextColor),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),

                    const SizedBox(height: 35),
                    
                    Text('Help & Support', style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: !isDark && isPremiumBlack ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
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
                                        Text('Quick guide to features, rest timer, & gestures', style: TextStyle(color: subTextColor, fontSize: 14)),
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

                    Text('Data', style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: !isDark && isPremiumBlack ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
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

                    Text('About', style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: !isDark && isPremiumBlack ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
                      ),
                      child: Column(
                        children: [
                          
                          BouncingWidget(
                            onTap: () => _launchUrl('https://github.com/chathushkaimasara'),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/developer.png', 
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                        cacheWidth: 104,
                                        gaplessPlayback: true,
                                        errorBuilder: (context, error, stackTrace) => Icon(Icons.code_rounded, color: subTextColor, size: 28),
                                      ),
                                    ),
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

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: BouncingWidget(
                                    onTap: () => _launchUrl('https://github.com/chathushkaimasara'),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/github_button.webp',
                                        height: 48,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        cacheWidth: 400,
                                        gaplessPlayback: true,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: BouncingWidget(
                                    onTap: () => _launchUrl('https://ko-fi.com/chathushkaimasara#payment-widget'),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/kofi_button.webp',
                                        height: 48,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        cacheWidth: 400,
                                        gaplessPlayback: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: dividerColor),

                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.asset(
                                    'assets/app_icon.webp', 
                                    width: 60, 
                                    height: 60, 
                                    fit: BoxFit.cover,
                                    cacheWidth: 120, 
                                    gaplessPlayback: true,
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
                                      Text(_appVersion, style: TextStyle(color: subTextColor, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: dividerColor),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: BouncingWidget(
                                    onTap: () => _launchUrl('https://github.com/chathushkaimasara/My-Workouts'),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/github_button.webp',
                                        height: 48,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        cacheWidth: 400,
                                        gaplessPlayback: true,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: BouncingWidget(
                                    onTap: () => _launchUrl('https://t.me/myworkoutsapp'),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/telegram_button.webp',
                                        height: 48,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        cacheWidth: 400,
                                        gaplessPlayback: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: dividerColor),

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
                            onTap: () => _showFontLicenseDialog(context, dialogBg, textColor, subTextColor),
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
                  ],
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(
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
                                backgroundColor: cardColor, 
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
              ),

            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// CUSTOM GUIDE PAGE WITH FULL RECENT FEATURE MANUAL
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

  Widget _buildGuideItem(IconData icon, String title, String description, Color textColor, Color subTextColor, Color cardColor, bool isDark, bool isPremiumBlack) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: !isDark && isPremiumBlack ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
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
    final bool useMaterialYou = appState.useMaterialYou;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    
    final bool isPremiumBlack = !useMaterialYou && appState.themePresetId == 'default_black';

    final Color bgColor = isPremiumBlack ? (isDark ? Colors.black : const Color(0xFFF2F2F7)) : scheme.surface;
    final Color textColor = isPremiumBlack ? (isDark ? Colors.white : Colors.black) : scheme.onSurface;
    final Color subTextColor = isPremiumBlack ? (isDark ? Colors.grey : Colors.grey.shade600) : scheme.onSurfaceVariant;
    final Color cardColor = isPremiumBlack ? (isDark ? const Color(0xFF141414) : Colors.white) : scheme.surfaceContainer;
    final Color frostedBg = isPremiumBlack ? (isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6)) : scheme.surface.withOpacity(isDark ? 0.8 : 0.7);
    
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
                
                // 1. SCHEDULE & HOMESCREEN
                _buildSectionTitle('Workouts & Schedule', textColor),
                _buildGuideItem(Icons.add_box_rounded, 'Adding a Workout Day', 'Tap the big "+" button on the home screen to create a new routine day (e.g., Push Day, Pull Day, Leg Day).', textColor, subTextColor, cardColor, isDark, isPremiumBlack),
                _buildGuideItem(Icons.swipe_rounded, 'Editing a Day Card', 'Press and hold any workout day card to open the quick menu. You can rename it, add a custom background picture, crop/position the photo, pin it to the top, or delete it.', textColor, subTextColor, cardColor, isDark, isPremiumBlack),
                _buildGuideItem(Icons.drag_handle_rounded, 'Reordering Days', 'Hold and drag any workout day card up or down to arrange your weekly schedule in any order.', textColor, subTextColor, cardColor, isDark, isPremiumBlack),
                
                // 2. HOMESCREEN CUSTOMIZATION
                _buildSectionTitle('Homescreen Customization', textColor),
                _buildGuideItem(Icons.dashboard_customize_rounded, 'Custom Layout & Toggles', 'Under Settings > Homescreen, you can toggle the Calendar, Rest Timer, and Motivational Quote widgets on or off.', textColor, subTextColor, cardColor, isDark, isPremiumBlack),
                _buildGuideItem(Icons.swap_vert_rounded, 'Reordering Widgets', 'Hold and drag the sliders in Settings > Homescreen to reposition widgets above or below each other.', textColor, subTextColor, cardColor, isDark, isPremiumBlack),
                _buildGuideItem(Icons.format_quote_rounded, 'Motivational Quote', 'When enabled on your homescreen, tap directly on the quote banner at any time to type and save your own custom daily motivation.', textColor, subTextColor, cardColor, isDark, isPremiumBlack),

                // 3. INSIDE THE GYM & REST TIMER
                _buildSectionTitle('Inside the Gym', textColor),
                _buildGuideItem(Icons.fitness_center_rounded, 'Adding Exercises & RPE', 'Inside a workout day, tap "+" to add exercises with target reps and optional RPE (Rate of Perceived Exertion).', textColor, subTextColor, cardColor, isDark, isPremiumBlack),
                _buildGuideItem(Icons.timer_outlined, 'Active Rest Pill', 'Checking off an exercise set automatically pops up the Active Rest pill at the bottom of the screen. Tap "+15s" to add more rest time or tap the skip button when ready to lift. Un-checking a set automatically dismisses the rest timer.', textColor, subTextColor, cardColor, isDark, isPremiumBlack),
                _buildGuideItem(Icons.emoji_events_outlined, 'All-Time High (PRs)', 'Press and hold any exercise in your workout list. The popup menu will display your all-time highest weight lifted for that lift.', textColor, subTextColor, cardColor, isDark, isPremiumBlack),
                _buildGuideItem(Icons.horizontal_rule_rounded, 'Dividers', 'Use the divider button in the "+" menu to section your warmups, main compounds, and accessory movements.', textColor, subTextColor, cardColor, isDark, isPremiumBlack),
                
                // 4. PROGRESS & BACKUPS
                _buildSectionTitle('Progress & Data', textColor),
                _buildGuideItem(Icons.bar_chart_rounded, 'The Progress Page', 'Tap the graph button on the bottom right of the homescreen to view your progress analytics across all lifts.', textColor, subTextColor, cardColor, isDark, isPremiumBlack),
                _buildGuideItem(Icons.add_chart_rounded, 'Logging Weight', 'Tap "+" next to an exercise on the Progress page to record weights and reps. The app automatically calculates your universal 1-Rep Max (1RM) and detects new PRs.', textColor, subTextColor, cardColor, isDark, isPremiumBlack),
                _buildGuideItem(Icons.backup_rounded, 'Seamless Backups', 'Export your workouts, custom pictures, and history under Settings > Data to securely backup or restore your progress to any device.', textColor, subTextColor, cardColor, isDark, isPremiumBlack),
                
              ],
            ),
          ),

          // FROSTED GLASS HEADER WITH GPU REPAINT BOUNDARY
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RepaintBoundary(
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
                            backgroundColor: cardColor, 
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
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// CUSTOM APP LICENSES PAGE WITH REPAINT BOUNDARY
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
    final bool useMaterialYou = widget.appState.useMaterialYou;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    
    final bool isPremiumBlack = !useMaterialYou && widget.appState.themePresetId == 'default_black';

    final Color bgColor = isPremiumBlack ? (isDark ? Colors.black : const Color(0xFFF2F2F7)) : scheme.surface;
    final Color textColor = isPremiumBlack ? (isDark ? Colors.white : Colors.black) : scheme.onSurface;
    final Color subTextColor = isPremiumBlack ? (isDark ? Colors.grey : Colors.grey.shade600) : scheme.onSurfaceVariant;
    final Color cardColor = isPremiumBlack ? (isDark ? const Color(0xFF141414) : Colors.white) : scheme.surfaceContainer;
    final Color frostedBg = isPremiumBlack ? (isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.6)) : scheme.surface.withOpacity(isDark ? 0.8 : 0.7);
    final Color dividerColor = isPremiumBlack ? (isDark ? Colors.white24 : Colors.black12) : scheme.outlineVariant.withOpacity(0.5);

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
                          Divider(color: dividerColor),
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
            child: RepaintBoundary(
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
                            backgroundColor: cardColor, 
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
          ),
        ],
      ),
    );
  }
}
