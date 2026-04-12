import 'dart:math';
import 'package:flutter/material.dart';

// Réactions — les 4 premières sont les plus populaires (affichées sans scroll)
const _kReactions = ['❤️', '😂', '🔥', '👍', '😍', '😮', '👏', '💜', '🧡', '💛'];

// Hauteur d'un item dans le picker vertical
const _kItemH = 52.0;
// Nombre d'items visibles sans scroll
const _kVisibleItems = 4;

class LiveReactionsOverlay extends StatefulWidget {
  /// Appelle [controller] pour exposer la méthode addReaction
  const LiveReactionsOverlay({super.key, required this.onControllerReady});
  final void Function(LiveReactionsController) onControllerReady;

  @override
  State<LiveReactionsOverlay> createState() => _LiveReactionsOverlayState();
}

class _LiveReactionsOverlayState extends State<LiveReactionsOverlay> {
  final _reactions = <_ReactionItem>[];

  @override
  void initState() {
    super.initState();
    widget.onControllerReady(LiveReactionsController._(_addReaction));
  }

  void _addReaction(String emoji) {
    final item = _ReactionItem(
      emoji: emoji,
      x: 0.5 + (Random().nextDouble() - 0.5) * 0.3,
      onDone: _removeReaction,
    );
    setState(() => _reactions.add(item));
  }

  void _removeReaction(_ReactionItem item) {
    if (mounted) setState(() => _reactions.remove(item));
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _reactions.map((r) => _ReactionWidget(item: r)).toList(),
      ),
    );
  }
}

// ─── Controller exposé à l'écran parent ──────────────────────────────────────

class LiveReactionsController {
  final void Function(String emoji) _add;
  LiveReactionsController._(this._add);
  void send(String emoji) => _add(emoji);
  void sendRandom() => _add(_kReactions[Random().nextInt(_kReactions.length)]);
}

// ─── Barre de sélection de réactions (bouton bas droite) ─────────────────────

// ─── Barre de sélection de réactions (bouton bas droite) ─────────────────────

class LiveReactionBar extends StatefulWidget {
  const LiveReactionBar({super.key, required this.controller});
  final LiveReactionsController controller;

  @override
  State<LiveReactionBar> createState() => _LiveReactionBarState();
}

class _LiveReactionBarState extends State<LiveReactionBar>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlay;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _close();
    _animCtrl.dispose();
    super.dispose();
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
  }

  void _showPicker() {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    // Hauteur du picker : exactement 4 items visibles
    const pickerH = _kItemH * _kVisibleItems;

    _overlay = OverlayEntry(builder: (ctx) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: Stack(children: [
          Positioned(
            // Positionné juste au-dessus du bouton, aligné à droite
            bottom: screenH - offset.dy + 8,
            right: screenW - offset.dx - size.width,
            child: ScaleTransition(
              alignment: Alignment.bottomRight,
              scale: CurvedAnimation(
                  parent: _animCtrl, curve: Curves.easeOutBack),
              child: Container(
                width: 60,
                height: pickerH,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(blurRadius: 12, color: Colors.black38)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: ListView.builder(
                    // scroll vers le bas pour voir plus d'emojis
                    itemCount: _kReactions.length,
                    itemExtent: _kItemH,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemBuilder: (_, i) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _close();
                        widget.controller.send(_kReactions[i]);
                      },
                      child: Center(
                        child: Text(
                          _kReactions[i],
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
    });

    Overlay.of(context).insert(_overlay!);
    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap simple → envoie ❤️
      onTap: () => widget.controller.send('❤️'),
      // Appui long → sélecteur d'emoji
      onLongPress: _showPicker,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: const Text('❤️', style: TextStyle(fontSize: 22)),
      ),
    );
  }
}

// ─── Item de réaction animé ───────────────────────────────────────────────────

class _ReactionItem {
  final String emoji;
  final double x; // 0.0 → 1.0 (position horizontale relative)
  final void Function(_ReactionItem) onDone;
  _ReactionItem({required this.emoji, required this.x, required this.onDone});
}

class _ReactionWidget extends StatefulWidget {
  const _ReactionWidget({required this.item});
  final _ReactionItem item;

  @override
  State<_ReactionWidget> createState() => _ReactionWidgetState();
}

class _ReactionWidgetState extends State<_ReactionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _y;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _sway;

  final _random = Random();

  @override
  void initState() {
    super.initState();
    final duration = Duration(milliseconds: 1800 + _random.nextInt(800));
    _ctrl = AnimationController(vsync: this, duration: duration)
      ..forward().whenComplete(() => widget.item.onDone(widget.item));

    // Montée (0 → -300px)
    _y = Tween<double>(begin: 0, end: -300 - _random.nextDouble() * 100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Fondu : opaque jusqu'à 70%, puis disparaît
    _opacity = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    // Scale : grandit légèrement au début
    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.5, end: 1.2)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
    ]).animate(_ctrl);

    // Balancement gauche-droite (sinusoïdal)
    _sway = Tween<double>(begin: -1.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: _SineCurve()));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final baseX = widget.item.x * screenW;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        bottom: 100 + (-_y.value),
        left: baseX + _sway.value * 18,
        child: Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _scale.value,
            child: Text(
              widget.item.emoji,
              style: TextStyle(
                fontSize: 28 + _random.nextDouble() * 8,
                shadows: const [
                  Shadow(blurRadius: 4, color: Colors.black26),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Courbe sinusoïdale pour le balancement
class _SineCurve extends Curve {
  @override
  double transformInternal(double t) => sin(t * pi * 2.5);
}
