import 'package:flutter/material.dart';

class BouncingWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapDownCallback? onTapDown;

  const BouncingWidget({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), 
      reverseDuration: const Duration(milliseconds: 300), 
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack, 
      ),
    );
    
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tapDown(TapDownDetails details) {
    widget.onTapDown?.call(details);
    _controller.forward();
  }

  void _tapUp(TapUpDetails details) {
    _controller.reverse();
    if (!_isTapped) {
      _isTapped = true;
      // THE FIX: This tiny delay gives the engine time to actually draw 
      // the bounce on screen before a dialog or new page steals the focus.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          widget.onTap?.call();
          _isTapped = false;
        }
      });
    }
  }

  void _tapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _tapDown,
      onTapUp: _tapUp,
      onTapCancel: _tapCancel,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Transform.scale(
        scale: _scaleAnimation.value,
        child: widget.child,
      ),
    );
  }
}
