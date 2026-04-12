import 'package:flutter/material.dart';

class LiveStreamScreen extends StatefulWidget {
  LiveStreamScreen({Key? key}) : super(key: key);

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildStreamPage());
  }

  Widget _buildStreamPage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF0f0f1e)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/images/photo.png',
                fit: BoxFit.contain, // évite le rognage
                width: double.infinity,
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage('assets/images/speaker_2.png'),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Fatemate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xffD4007A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '10K',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 12,
            bottom: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildComment('Moi', 'Super 😍'),
                SizedBox(height: 10),
                _buildComment('Quelqu\'un', '❤️ Super'),
                SizedBox(height: 10),
                _buildComment('Vania', '👍😊'),
                SizedBox(height: 10),
                _buildComment('Moi', '🥰🥰🥰'),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Comment',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {}, // ajouter logique du cœur plus tard
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(String username, String text) {
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundImage: AssetImage('assets/images/speaker_2.png'),
        ),
        SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              username,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(text, style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
