import 'package:flutter/material.dart';
import 'package:siade2/src/features/home/pages/app_layout.dart';
import 'package:siade2/src/features/home/pages/home_page.dart';

class ProgramPage extends StatefulWidget {
  const ProgramPage({super.key});

  @override
  _ProgramPageState createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back),
              ),
          
              Text('PROFIL', style: TextStyle(color: Colors.white)),
          
              IconButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => AppLayout()),
                  (route) => false,
                ),
                icon: Icon(Icons.arrow_back),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
