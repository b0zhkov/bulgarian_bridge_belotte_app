import 'package:flutter/material.dart' hide Card;

import '../../../core/agents/bot_names.dart';
import '../../../core/models/card.dart';
import 'playing_card.dart';

/// Paints what the table draws (card faces and backs in every variant,
/// the flying-card transforms, avatar emoji, the app font) once at app
/// start, underneath the opaque screens, then removes itself. This moves
/// the one-off first-paint costs (shader compilation, glyph atlases, the
/// web emoji font download) out of the deal animation, whose first frames
/// used to stall for 150–340 ms each.
class TableWarmUp extends StatefulWidget {
  const TableWarmUp({super.key, this.frames = 30});

  /// Frames to keep painting (a few, so late-loading fonts get drawn too).
  final int frames;

  @override
  State<TableWarmUp> createState() => _TableWarmUpState();
}

class _TableWarmUpState extends State<TableWarmUp> {
  int _frames = 0;

  /// Off under flutter_test: nothing to warm up there, and its cards
  /// would show up in widget finders.
  static final bool _inTest = WidgetsBinding.instance.runtimeType
      .toString()
      .contains('TestWidgetsFlutterBinding');

  @override
  void initState() {
    super.initState();
    if (_inTest) {
      _frames = widget.frames;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback(_frame);
  }

  void _frame(Duration _) {
    if (!mounted) return;
    setState(() => _frames++);
    if (_frames < widget.frames) {
      WidgetsBinding.instance.addPostFrameCallback(_frame);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_frames >= widget.frames) return const SizedBox.shrink();
    const back = RepaintBoundary(
      child: PlayingCardView(card: null, faceUp: false, width: 34),
    );
    final cards = [
      for (final (i, s) in Suit.values.indexed)
        Card(s, Rank.values[(i * 3) % Rank.values.length]),
    ];
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(
          width: 400,
          height: 260,
          child: Stack(
            children: [
              Wrap(
                children: [
                  for (final (i, c) in cards.indexed)
                    PlayingCardView(
                      card: c,
                      width: i.isEven ? 76 : 56,
                      highlighted: i == 1,
                      dimmed: i == 2,
                      glow: i == 3,
                    ),
                  const PlayingCardView(card: null, faceUp: false, width: 56),
                  Text(
                    '$kBotAvatar${kHumanAvatars.join()} 0123456789 :—',
                    style: const TextStyle(fontSize: 30, height: 1.1),
                  ),
                  for (final w in [
                    FontWeight.w300,
                    FontWeight.w400,
                    FontWeight.w600,
                  ])
                    Text('Ние Вие АБВ', style: TextStyle(fontWeight: w)),
                ],
              ),
              Transform.translate(
                offset: const Offset(120, 40),
                child: Transform.scale(
                  scale: 1.4,
                  child: const Opacity(opacity: 0.5, child: back),
                ),
              ),
              Transform.translate(offset: const Offset(180, 60), child: back),
            ],
          ),
        ),
      ),
    );
  }
}
