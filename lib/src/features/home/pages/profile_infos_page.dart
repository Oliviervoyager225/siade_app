import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siade2/src/providers/providers.dart';
import 'package:siade2/src/commons/utils/utils.dart';
import 'package:siade2/src/theme/theme.dart';
import 'package:sizer/sizer.dart';

class ProfileInfosPage extends StatefulWidget {
  const ProfileInfosPage({super.key});

  @override
  _ProfileInfosPageState createState() => _ProfileInfosPageState();
}

class _ProfileInfosPageState extends State<ProfileInfosPage> {
  final double photoProfileBoxSize = 150.0;

  double get photoProfileSize => photoProfileBoxSize * 0.95;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF60438C).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFF070054),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 30),
                      Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF07026F), Color(0xFFA01E38)],
                          ),
                          border: Border.all(color: Colors.transparent, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: CircleAvatar(
                            backgroundImage: AssetImage("assets/images/photo_profile.jpg"),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          final user = userProvider.user;
                          return Column(
                            children: [
                              Text(
                                user?['username'] ?? user?['name'] ?? 'Utilisateur',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              Text(
                                (user?['poste'] ?? 'Visiteur').toString(),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 30),
                      // Speech bubble with QR
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              color: Color(0xFF0D69C1),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(125),
                                topRight: Radius.circular(125),
                                bottomLeft: Radius.circular(125),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                          ),
                          Container(
                            width: 180,
                            height: 180,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Image.asset("assets/images/qr_code.png"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: socialMedias.map((socialAsset) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Color(0xFF60438C),
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(10),
                      child: Image.asset(
                        socialAsset,
                        color: Colors.white,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              Text(
                '@siade',
                style: TextStyle(
                  color: Color(0xFF60438C),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

}
