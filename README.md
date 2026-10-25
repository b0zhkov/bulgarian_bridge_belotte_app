# Белот (Bulgarian Bridge Belote)

Flutter app for Android, iOS and web. Rules follow [belot.bg](https://belot.bg/belot/rules/) exactly.

## Status — milestone 1
- Pure Dart rules engine (`lib/core/rules`, no Flutter imports): 3+2 / 3 dealing, bidding with overcalls,
  contra / recontra, all-pass redeal, legal moves for suit / No Trump / All Trump, trick resolution,
  automatic declarations (tierce, quarte, quint, squares) and their comparison, belot, last 10, valat,
  scoring with outside / inside / hanging (carry-over), belot.bg rounding per contract, double / redouble,
  match end at 151 (tie continues, cannot win on a valat).
- Seedable deterministic RNG, immutable `GameState`.
- Offline table in the Offsuit style (dark default + light theme toggle), Bulgarian UI via ARB/intl.
- The three other seats use a placeholder `RandomAgent` (random legal moves) behind the
  `PlayerAgent` interface (`lib/core/agents`). Real bots come later.

## Structure
```
lib/
├── core/
│   ├── agents/      # PlayerAgent interface + placeholder RandomAgent
│   ├── constants/
│   ├── models/      # Card, Suit, Rank, Contract, Bid, Trick
│   ├── rules/       # BelotEngine, legal moves, declarations, scoring, GameState
│   ├── theme/       # Design tokens (dark / light)
│   └── widgets/     # Pill buttons, vector suit icons
├── features/
│   ├── game/        # Table screen, controller (Riverpod), card widgets, result panel
│   ├── home/
│   ├── lobby/       # (phase 2)
│   ├── multiplayer/ # (phase 2)
│   └── settings/    # Theme toggle (persisted)
├── l10n/            # app_bg.arb (template), app_en.arb
└── main.dart
```

## Develop
```
flutter pub get
flutter test             # engine + widget tests
flutter run -d chrome    # or an Android device
flutter build web        # build/web
flutter build apk        # build/app/outputs/flutter-apk/app-release.apk
```
The table can be opened directly at `/#/game` on web.

Fonts: Inter (SIL Open Font License, see `assets/fonts/Inter-LICENSE.txt`).
