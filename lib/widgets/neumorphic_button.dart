import 'package:flutter/material.dart';

class NeumorphicButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const NeumorphicButton({
    super.key, 
    required this.icon, 
    required this.label, 
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2D34) : const Color(0xFFE0E5EC),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : const Color(0xFFA3B1C6),
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: isDark ? const Color(0xFF383C45) : Colors.white,
              offset: const Offset(-4, -4),
              blurRadius: 8,
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.white60,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
