import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/suit_icon.dart';
import '../../l10n/generated/app_localizations.dart';
import '../game/widgets/playing_card.dart';
import '../../core/models/card.dart' as m;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              children: [
                Row(
                  children: [
                    Row(
                      children: [
                        for (final suit in const [
                          m.Suit.spades,
                          m.Suit.hearts,
                          m.Suit.clubs,
                          m.Suit.diamonds,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SuitIcon(
                              suit,
                              size: 16,
                              color: suit.isRed ? c.cardRed : c.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      key: const Key('open-settings'),
                      icon: Icon(Icons.settings_outlined, color: c.textPrimary),
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/settings'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  l.appTitle,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 76,
                    fontWeight: FontWeight.w300,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 32),
                _ModeCard(
                  key: const Key('play-offline'),
                  title: l.homeOfflineTitle,
                  subtitle: l.homeOfflineSubtitle,
                  colors: const [Color(0xFFE4E9FF), Color(0xFFDDF0D8)],
                  art: const _FannedCards(),
                  onTap: () => Navigator.of(context).pushNamed('/game'),
                ),
                const SizedBox(height: 14),
                _ModeCard(
                  title: l.homeOnlineTitle,
                  subtitle: l.homeOnlineSubtitle,
                  colors: const [Color(0xFFFFE3E0), Color(0xFFFFF1D6)],
                  art: const Text('👥', style: TextStyle(fontSize: 48)),
                  onTap: null,
                ),
                const SizedBox(height: 28),
                Text(
                  l.homeRulesTitle,
                  style: TextStyle(color: c.textPrimary, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  l.rulesBody,
                  style: TextStyle(color: c.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 6),
                Text(
                  l.homeRulesSubtitle,
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.art,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final List<Color> colors;
  final Widget art;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.7 : 1,
      child: Material(
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 84, child: art),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF444444),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FannedCards extends StatelessWidget {
  const _FannedCards();

  @override
  Widget build(BuildContext context) {
    const cards = [
      m.Card(m.Suit.spades, m.Rank.jack),
      m.Card(m.Suit.hearts, m.Rank.nine),
      m.Card(m.Suit.clubs, m.Rank.ace),
    ];
    return SizedBox(
      width: 140,
      child: Stack(
        children: [
          for (final (i, card) in cards.indexed)
            Positioned(
              left: i * 30.0,
              top: 0,
              child: Transform.rotate(
                angle: (i - 1) * 0.12,
                child: PlayingCardView(card: card, width: 58),
              ),
            ),
        ],
      ),
    );
  }
}
