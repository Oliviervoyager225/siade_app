import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

class OutlineButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;

  const OutlineButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isLight ? Colors.white.withOpacity(0.6) : null,
        border: Border.all(
          color: isLight ? Colors.transparent : Colors.white24,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Image.asset(
                    'assets/images/google.png', 
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: isLight ? Color(0xFF60438C) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
