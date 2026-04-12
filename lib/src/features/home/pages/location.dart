import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Location extends StatefulWidget {
  const Location({super.key});

  @override
  State<Location> createState() => _LocationState();
}

class _LocationState extends State<Location> {
  GoogleMapController? _controller;

  static const LatLng _start = LatLng(51.538, -0.142); // départ
  static const LatLng _end = LatLng(51.540, -0.136); // arrivée

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();

    _markers.add(
      Marker(
        markerId: MarkerId('start'),
        position: _start,
        infoWindow: InfoWindow(title: 'Départ'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    _markers.add(
      const Marker(
        markerId: MarkerId('end'),
        position: _end,
        infoWindow: InfoWindow(title: 'Arrivée'),
      ),
    );

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route1'),
        color: Colors.blueAccent,
        width: 5,
        points: [
          _start,
          const LatLng(51.539, -0.140),
          const LatLng(51.540, -0.138),
          _end,
        ],
      ),
    );

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route2'),
        color: Colors.redAccent,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.dash(10)],
        points: [
          _start,
          const LatLng(51.539, -0.141),
          const LatLng(51.540, -0.139),
          _end,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 🗺️ --- Carte Google Maps ---
            // GoogleMap(
            //   initialCameraPosition: const CameraPosition(
            //     target: LatLng(51.539, -0.139),
            //     zoom: 16.5,
            //   ),
            //   markers: _markers,
            //   polylines: _polylines,
            //   myLocationButtonEnabled: false,
            //   zoomControlsEnabled: false,
            //   onMapCreated: (controller) => _controller = controller,
            // ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/tracking'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // 🔍 --- Barre de recherche en haut ---
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1B1F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_pin, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Sah analytics",
                              hintStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.swap_vert,
                            color: Colors.white70,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1B1F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Sah analytics",
                              hintStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        const Icon(Icons.mic, color: Colors.white70),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🚶 --- Options de durée ---
            Positioned(
              top: 180,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModeButton("2 min", Icons.directions_walk),
                  _buildModeButton(
                    "3 min",
                    Icons.directions_car,
                    selected: true,
                  ),
                  _buildModeButton("2 min", Icons.pedal_bike),
                ],
              ),
            ),

            // 📍 --- Info itinéraire bleu ---
            Positioned(
              top: 280,
              left: 60,
              child: _routeInfoBox(
                "3 min",
                "Safe, pedestrian lighting",
                Colors.blueAccent,
                Icons.thumb_up_alt,
              ),
            ),

            // 📍 --- Info itinéraire rouge ---
            Positioned(
              top: 360,
              right: 60,
              child: _routeInfoBox(
                "2 min",
                "Unsafe, 2 prev. incidents",
                Colors.redAccent,
                Icons.warning_amber_rounded,
              ),
            ),

            // 📦 --- Bottom sheet d’aperçu ---
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C21),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "3 min (0.1 mi)",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Lorem ipsum is placeholder",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      label: const Text(
                        "Preview",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧱 Widget utilitaire pour les modes de transport
  Widget _buildModeButton(String text, IconData icon, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.blueAccent : Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // 🧱 Widget utilitaire pour les étiquettes d’itinéraire
  Widget _routeInfoBox(String time, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
