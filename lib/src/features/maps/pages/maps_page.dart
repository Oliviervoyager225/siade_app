import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsNavigationScreen extends StatefulWidget {
  const MapsNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MapsNavigationScreen> createState() => _MapsNavigationScreenState();
}

class _MapsNavigationScreenState extends State<MapsNavigationScreen> {
  static const double _destLat = 5.328253829674609;
  static const double _destLng = -4.018529150561443;
  static const String _destName = 'Lieu SIADE';

  Future<void> _openNavigation() async {
    // Tente d'ouvrir l'app de navigation native (Google Maps / Plans)
    final geoUri = Uri.parse(
      'geo:$_destLat,$_destLng?q=$_destLat,$_destLng($_destName)',
    );
    final googleUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$_destLat,$_destLng'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
    }
  }
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryColor = isLight ? Color(0xFF60438C) : Colors.white;
    final secondaryBg = isLight ? Colors.grey[200] : const Color(0xFF2C2C2E);
    final scaffoldBg = isLight ? Colors.white : Colors.black;

    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/mapbg.png'),
                fit: BoxFit.cover,
                colorFilter: isLight 
                    ? ColorFilter.mode(Colors.white.withOpacity(0.7), BlendMode.screen)
                    : null,
              ),
            ),
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: scaffoldBg,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status bar time placeholder
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '9:41',
                            style: TextStyle(
                              color: isLight ? Colors.black : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Header avec recherche
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: secondaryBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Première ligne - Départ
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: isLight ? Colors.black : Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.blue, width: 2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Sah analytics',
                                    style: TextStyle(
                                      color: isLight ? Colors.black : Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.more_vert,
                                  color: isLight ? Colors.black : Colors.white,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),

                          Container(
                            height: 1,
                            margin: const EdgeInsets.only(left: 46),
                            color: isLight ? Colors.black12 : Colors.white24,
                          ),

                          // Deuxième ligne - Arrivée
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                            child: Row(
                              children: [
                                const SizedBox(width: 34),
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _destName,
                                        style: TextStyle(
                                          color: isLight ? Colors.black : Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${_destLat.toStringAsFixed(4)}, ${_destLng.toStringAsFixed(4)}',
                                        style: TextStyle(
                                          color: isLight ? Colors.black45 : Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isLight ? Colors.black12 : Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.swap_vert,
                                    color: isLight ? Colors.black : Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Options de transport
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      decoration: BoxDecoration(
                        color: secondaryBg,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTransportOption(Icons.directions_car, '2 min', true, isLight),
                          _buildTransportOption(Icons.train, '', false, isLight),
                          _buildTransportOption(Icons.directions_walk, '3 min', false, isLight),
                          _buildTransportOption(Icons.directions_bike, '', false, isLight),
                          _buildTransportOption(Icons.pedal_bike, '2 min', false, isLight),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // Route Info Box (Blue)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.thumb_up, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    '3 min',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Safe pedestrian lighting label
          Positioned(
            top: MediaQuery.of(context).size.height * 0.42,
            left: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                'Safe, pedestrian lighting',
                style: TextStyle(
                  color: isLight ? Colors.black : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Unsafe label (Info Box)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.48,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 14),
                  SizedBox(width: 6),
                  Text(
                    '2 min',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).size.height * 0.54,
            right: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                'Unsafe, 2 prev. incidents',
                style: TextStyle(
                  color: isLight ? Colors.black : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Right side buttons
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.28,
            child: Column(
              children: [
                _buildRoundButton(Icons.layers_outlined, isLight),
                const SizedBox(height: 12),
                _buildRoundButton(Icons.search, isLight),
              ],
            ),
          ),

          // Current location button
          Positioned(
            right: 16,
            bottom: 220,
            child: _buildRoundButton(Icons.my_location, isLight),
          ),

          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: scaffoldBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isLight ? Colors.black12 : Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Route info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '3 min',
                              style: TextStyle(
                                color: isLight ? Colors.black : Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(0.1 mi)',
                              style: TextStyle(
                                color: isLight ? Colors.black54 : Colors.white60,
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _destName,
                          style: TextStyle(
                            color: isLight ? Colors.black54 : Colors.white60,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bouton navigation
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _openNavigation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.navigation_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Démarrer la navigation',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Safe area pour l'indicateur d'accueil
                  Container(
                    height: MediaQuery.of(context).padding.bottom > 0 
                        ? MediaQuery.of(context).padding.bottom 
                        : 20,
                    color: scaffoldBg,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportOption(IconData icon, String time, bool isSelected, bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? (isLight ? Colors.black : Colors.white) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected 
                ? (isLight ? Colors.white : Colors.black) 
                : (isLight ? Colors.black54 : Colors.white70),
            size: 18,
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              time,
              style: TextStyle(
                color: isSelected 
                    ? (isLight ? Colors.white : Colors.black) 
                    : (isLight ? Colors.black54 : Colors.white70),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoundButton(IconData icon, bool isLight) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.black87,
        size: 20,
      ),
    );
  }
}