import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../state/workout_state.dart';
import '../widgets/bouncing_widget.dart';
import 'home_page.dart';

class WelcomePage extends StatefulWidget {
  final WorkoutState appState;

  const WelcomePage({super.key, required this.appState});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  
  bool _isPickingImage = false; 
  bool _isFinishing = false; 

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.appState.userName != "My Name" ? widget.appState.userName : "";
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _prevPage() {
    HapticFeedback.lightImpact();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _finishOnboarding() {
    if (_isFinishing) return; 
    HapticFeedback.heavyImpact();
    
    if (_nameController.text.trim().isNotEmpty) {
      widget.appState.updateUserName(_nameController.text.trim());
    }

    // THE FIX: Trigger the fast fade-out
    setState(() {
      _isFinishing = true;
    });

    // THE FIX: Snappy 300ms delay, then straight into the Home Page without the dumbbell
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      widget.appState.completeFirstLaunch();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500), // Sped up transition
          pageBuilder: (context, animation, secondaryAnimation) => HomePage(appState: widget.appState),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
                ),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  Future<void> _pickProfileImage() async {
    if (_isPickingImage) return; 
    setState(() => _isPickingImage = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), 
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Profile Picture',
              toolbarColor: const Color(0xFF121212),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              cropStyle: CropStyle.circle, 
            ),
          ],
        );

        if (croppedFile != null) {
          widget.appState.updateProfileImage(croppedFile.path);
          setState(() {}); 
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ALL UI ELEMENTS (Fades out flawlessly when finishing)
          AnimatedOpacity(
            opacity: _isFinishing ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Stack(
              children: [
                PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildPageContent(
                      imagePath: 'assets/welcome_bg.png',
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStylishTitle('Every\n', 'Rep ', 'Counts'),
                          const SizedBox(height: 20),
                          _buildSubtitle('Plan tasks, stay focused, and achieve your goals with simple daily organization.'),
                        ],
                      ),
                    ),
                    _buildPageContent(
                      imagePath: 'assets/onboard2.png',
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStylishTitle('Plan Your\n', 'Perfect ', 'Routine'),
                          const SizedBox(height: 20),
                          _buildSubtitle('Customize your daily workouts and structure your week for maximum gains.'),
                        ],
                      ),
                    ),
                    _buildPageContent(
                      imagePath: 'assets/onboard3.png',
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStylishTitle('Track Your\n', 'Strength ', 'Growth'),
                          const SizedBox(height: 20),
                          _buildSubtitle('Log your heavy lifts and watch your personal records climb over time.'),
                        ],
                      ),
                    ),
                    _buildPageContent(
                      imagePath: 'assets/onboard4.png',
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStylishTitle('Minimal Design,\n', 'Maximum ', 'Results'),
                          const SizedBox(height: 20),
                          _buildSubtitle('Zero clutter. Just you, your schedule, and the weights.'),
                        ],
                      ),
                    ),
                    _buildPageContent(
                      imagePath: 'assets/onboard5.png',
                      isCenter: true,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Who's lifting today?",
                            style: TextStyle(fontFamily: 'WorkoutFont', fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 40),
                          BouncingWidget(
                            onTap: _pickProfileImage,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  backgroundImage: widget.appState.profileImagePath != null && File(widget.appState.profileImagePath!).existsSync() 
                                      ? FileImage(File(widget.appState.profileImagePath!)) 
                                      : null,
                                  child: widget.appState.profileImagePath == null 
                                      ? const Icon(Icons.person, color: Colors.white54, size: 60) 
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F54F),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 4),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.black, size: 18),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            cursorColor: const Color(0xFFE8F54F),
                            decoration: InputDecoration(
                              hintText: 'Enter your name',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE8F54F))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Floating Nav Buttons
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 30.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                        child: _currentPage == 0
                            ? IosSlideToStart(
                                key: const ValueKey('slider'),
                                onComplete: _nextPage,
                              )
                            : _buildNavPill(
                                key: const ValueKey('pill'),
                                text: _currentPage == 4 ? 'Let\'s Go!' : 'Continue',
                                isLast: _currentPage == 4,
                              ),
                      ),
                    ),
                  ),
                ),

                // Floating Skip Button
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IgnorePointer(
                      ignoring: _currentPage != 4, 
                      child: AnimatedOpacity(
                        opacity: _currentPage == 4 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: BouncingWidget(
                          onTap: _currentPage == 4 ? _finishOnboarding : () {},
                          child: const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('Skip >', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent({required String imagePath, required Widget content, bool isCenter = false}) {
    return Stack(
      children: [
        Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),
        _buildDarkGradient(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 130.0), 
            child: Align(
              alignment: isCenter ? Alignment.bottomCenter : Alignment.bottomLeft,
              child: content,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDarkGradient() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.transparent, Colors.black87, Colors.black],
            stops: [0.0, 0.4, 0.75, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildStylishTitle(String p1, String p2, String p3) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'WorkoutFont', fontSize: 52, color: Colors.white, fontWeight: FontWeight.bold, height: 1.1),
        children: [
          TextSpan(text: p1),
          TextSpan(text: p2, style: const TextStyle(color: Color(0xFFE8F54F), fontStyle: FontStyle.italic)),
          TextSpan(text: p3),
        ],
      ),
    );
  }

  Widget _buildSubtitle(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, height: 1.5),
    );
  }

  // THE FIX: Cleaned up the '>>' text
  Widget _buildNavPill({required Key key, required String text, required bool isLast}) {
    return Row(
      key: key,
      children: [
        BouncingWidget(
          onTap: _prevPage,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withOpacity(0.9), 
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
        ),
        
        const SizedBox(width: 15),
        
        Expanded(
          child: BouncingWidget(
            onTap: isLast ? _finishOnboarding : _nextPage,
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E).withOpacity(0.9),
                borderRadius: BorderRadius.circular(35),
              ),
              alignment: Alignment.center, 
              child: Text(
                text, 
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// CUSTOM IOS-STYLE SLIDER ENGINE (Used on Page 1)
// ---------------------------------------------------------
class IosSlideToStart extends StatefulWidget {
  final VoidCallback onComplete;

  const IosSlideToStart({super.key, required this.onComplete});

  @override
  State<IosSlideToStart> createState() => _IosSlideToStartState();
}

class _IosSlideToStartState extends State<IosSlideToStart> with TickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;

  late AnimationController _snapController;
  late Animation<double> _snapAnimation;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _snapController.addListener(() {
      setState(() {
        _dragPosition = _snapAnimation.value;
      });
    });

    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _snapController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (_isCompleted) return;
    setState(() {
      _dragPosition += details.delta.dx;
      if (_dragPosition < 0) _dragPosition = 0;
      final maxDrag = maxWidth - 70; 
      if (_dragPosition > maxDrag) _dragPosition = maxDrag;
    });
  }

  void _onDragEnd(DragEndDetails details, double maxWidth) {
    if (_isCompleted) return;
    final maxDrag = maxWidth - 70;
    
    if (_dragPosition > maxDrag * 0.8) {
      setState(() {
        _dragPosition = maxDrag;
        _isCompleted = true;
      });
      widget.onComplete();
    } else {
      _snapAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _snapController, curve: Curves.easeOutBack),
      );
      _snapController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxDrag = maxWidth - 70;
        final textOpacity = (1.0 - (_dragPosition / (maxDrag * 0.5))).clamp(0.0, 1.0);

        return Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), 
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    final shimmerOpacity = 0.3 + (_shimmerController.value * 0.7);
                    return Opacity(opacity: textOpacity * shimmerOpacity, child: child);
                  },
                  child: const Text('slide to get started', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                ),
              ),
              Positioned(
                left: _dragPosition + 7, 
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxWidth),
                  onHorizontalDragEnd: (details) => _onDragEnd(details, maxWidth),
                  child: Container(
                    width: 56, 
                    height: 56,
                    decoration: const BoxDecoration(color: Color(0xFFE8F54F), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black, size: 22),
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
