import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// Widget PreviewVideo avec contrôles
class PreviewVideo extends StatefulWidget {
  final String url;
  final bool autoPlay;

  const PreviewVideo({Key? key, required this.url, this.autoPlay = true})
    : super(key: key);

  @override
  _PreviewVideoState createState() => _PreviewVideoState();
}

class _PreviewVideoState extends State<PreviewVideo> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  double _currentSliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    // Initialiser avec URL réseau ou asset
    // if (widget.video.url.startsWith('http')) {
    //   _controller = VideoPlayerController.networkUrl(
    //     Uri.parse(widget.video.url),
    //   );
    // } else {
    //   _controller = VideoPlayerController.asset(widget.video.url);
    // }
    //
    // _controller.initialize().then((_) {
    //   setState(() {});
    //   if (widget.autoPlay) {
    //     _controller.play();
    //     _isPlaying = true;
    //   }
    //   _controller.setLooping(true);
    // });
    //
    // // Écouter les changements de position
    // _controller.addListener(() {
    //   if (_controller.value.isInitialized) {
    //     setState(() {
    //       _currentSliderValue = _controller.value.position.inMilliseconds
    //           .toDouble();
    //     });
    //   }
    // });

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..addListener(() {
        if (_controller.value.isInitialized) {
          setState(() {
            _currentSliderValue = _controller.value.position.inMilliseconds
                .toDouble();
          });
        }
      })
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _isPlaying = true;
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _seekForward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition + Duration(seconds: 10);
    final duration = _controller.value.duration;

    if (newPosition < duration) {
      _controller.seekTo(newPosition);
    } else {
      _controller.seekTo(duration);
    }
  }

  void _seekBackward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - Duration(seconds: 10);

    if (newPosition > Duration.zero) {
      _controller.seekTo(newPosition);
    } else {
      _controller.seekTo(Duration.zero);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Vidéo en plein écran
          Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : Center(child: CircularProgressIndicator(color: Colors.white)),
          ),

          // Zone cliquable pour afficher/masquer les contrôles
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: Container(color: Colors.transparent),
          ),

          // Contrôles overlay
          if (_showControls)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),

          // Bouton retour (en haut à gauche)
          if (_showControls)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

          // Bouton favoris (en haut à droite)
          if (_showControls)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () {
                    // Action favoris
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),

          // Contrôles centraux (play/pause, avance, recule)
          if (_showControls)
            Positioned(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Bouton reculer 10s
                  _buildControlButton(
                    icon: Icons.replay_10,
                    onPressed: _seekBackward,
                  ),
                  SizedBox(width: 40),

                  // Bouton Play/Pause
                  _buildControlButton(
                    icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                    onPressed: _togglePlayPause,
                    size: 70,
                  ),
                  SizedBox(width: 40),

                  // Bouton avancer 10s
                  _buildControlButton(
                    icon: Icons.forward_10,
                    onPressed: _seekForward,
                  ),
                ],
              ),
            ),

          // Barre de progression en bas
          if (_showControls && _controller.value.isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Slider de progression
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          value: _currentSliderValue,
                          min: 0.0,
                          max: _controller.value.duration.inMilliseconds
                              .toDouble(),
                          activeColor: Colors.white,
                          inactiveColor: Colors.white.withOpacity(0.3),
                          onChanged: (value) {
                            setState(() {
                              _currentSliderValue = value;
                            });
                            _controller.seekTo(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                      ),

                      // Temps actuel / Durée totale
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_controller.value.position),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 50,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.6),
      ),
    );
  }
}
