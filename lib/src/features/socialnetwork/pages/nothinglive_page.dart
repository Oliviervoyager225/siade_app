import 'package:flutter/material.dart';

class NoStreamScreen extends StatefulWidget {
   NoStreamScreen({Key? key}) : super(key: key);

  @override
  State<NoStreamScreen> createState() => _NoStreamScreenState();
}

class _NoStreamScreenState extends State<NoStreamScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color(0xFF0f0f1e),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:  EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              ),
            ),
             Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                  'Aucun',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                 SizedBox(height: 8),
                Container(
                  padding:
                       EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xffD4007A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
             Spacer(),
          ],
        ),
      ),
    );
  }
}
