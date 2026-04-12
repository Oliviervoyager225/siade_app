import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

class CustomTextField extends StatefulWidget {
  final IconData icon;
  final String hint;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const CustomTextField({
    Key? key,
    required this.icon,
    required this.hint,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: isLight ? Color(0xFFF5E6F0).withOpacity(0.6) : null,
        border: Border.all(
          color: isLight ? Colors.transparent : Colors.white24,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        style: TextStyle(
          color: isLight ? Color(0xFF60438C) : Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            widget.icon,
            color: isLight ? Color(0xFF60438C) : Color(0xff2563EB),
            size: 22,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: isLight ? Color(0xFF60438C) : Color(0xff2563EB),
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: isLight ? Color(0xFF60438C).withOpacity(0.5) : Color(0xff64748B),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        ),
      ),
    );
  }
}