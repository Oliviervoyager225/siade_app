import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

class GradientButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final bool isFullWidth;
  final VoidCallback onTap;

   GradientButton({
    Key? key,
    required this.text,
    required this.isActive,
    this.isFullWidth = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    // For full-width button in light mode, use white background with purple text
    if (isLight && isFullWidth) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: onTap,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: Color(0xFFB8A0D0), // Light purple text
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // For toggle buttons (Login/Sign up) in light mode, use gradient
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight 
              ? [Color(0xFF60438C), Color(0xFFFFFFFF)] // Purple (top) to white (bottom)
              : [Color(0xFF180468), Color(0xFFD2044E)],
          begin: isLight ? Alignment.topCenter : Alignment.centerLeft,
          end: isLight ? Alignment.bottomCenter : Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Container(
        margin: isLight ? EdgeInsets.all(0) : EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isLight ? Colors.transparent : Color(0xFF180468).withOpacity(0.45),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(23),
            onTap: onTap,
            child: Center(
              child: Text(
                text,
                style:  TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
