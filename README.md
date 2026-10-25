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

## Beta 2
- First-launch name prompt (2–16 chars, letters/digits/space/. - _), editable in Settings.
- Home: Stats card (matches, wins, win rate) → Stats screen (deals, avg points per deal, contracts made, valats), stored locally.
- Table: partner opposite (top), opponents left/right, team colour rings and "Партньор"/"Противник" labels, "Ние"/"Вие" scores in team colours.
- Hints: after 25 s of inactivity on your card turn a suggested legal card glows (`lib/core/agents/hint.dart`); toggle in Settings (on by default).
- Live web build: https://b0zhkov.github.io/bulgarian_bridge_belotte_app/

## Beta 3 — online play with room codes
- Home → "Игра с приятели": create a room (5-char code, alphabet without 0/O/1/I/L) or join by code.
  Invite link: `https://b0zhkov.github.io/bulgarian_bridge_belotte_app/?room=CODE` pre-fills the code.
- Lobby: "Отбор 1" / "Отбор 2" (max 2 each, switch while the other team has room). The host can fill empty
  seats with bots once each team has a human, then start. Partners sit opposite.
- Joining mid-game → waiting screen; you take a bot's seat (team of your choice) when the current deal ends.
- Disconnect → a bot plays the seat immediately; reconnecting with the same code within the deal reclaims it.
  If the host leaves, the earliest-joined online human becomes host; the last human leaving deletes the room.
- After a match everyone returns to the lobby. The room code is shown under the hand (tap to copy the invite).
- Timers (online and offline, separate toggles in Settings): hint after 25 s, auto-play of the hint after 40 s.

### Architecture
- Firebase Anonymous Auth + Realtime Database (`europe-west1`), host-authoritative:
  clients only write `intents/{uid}`, `members/{uid}` (presence/team); the host runs the engine and writes
  `pub` (public state), `seats`, `hands/{uid}` (readable only by that uid) and `hostState/{code}`.
- `lib/online/` — `Db` abstraction (Firebase + in-memory fake), `RoomLogic` (pure lobby/seat rules),
  `HostDriver`, `RoomClient`. `lib/features/online/` — UI. Engine additions: `StateCodec`, `rotateState`.
- Security rules: `database.rules.json`. Deploy with `firebase deploy --only database`
  (project `bulgarian-bridge-belotte-app`, see `.firebaserc`).
- Anonymous sign-in does not need the hosting domain in Auth → Settings → Authorized domains
  (that list only matters for OAuth popup/redirect providers).

## Beta 4 — real bots
- `lib/core/agents/` (pure Dart, deterministic per seed): `BotAgent` behind `PlayerAgent` with three levels:
  **Лесно** (heuristics, noisy bidding, ~30% random cards), **Средно** (heuristics + `CardMemory`: played cards,
  voids and "no higher card" limits inferred from follow/trump/raise duties, cards shown in declarations/belot),
  **Трудно** (Средно + determinized Monte Carlo: samples unseen hands consistent with that knowledge and plays
  each candidate out; ≤250 ms per move in a background isolate on mobile, 150 ms inline on web).
- Bidding (`bidding.dart`): per-contract hand evaluation (trump J/9, aces/10s, length, belot, sequences/squares,
  partner's bids), overcall margins, contra/recontra only with strong hands; legality from the engine.
- Offline: choose the difficulty when starting (default in Settings). Online: the host picks it in the lobby
  (`rooms/{code}/meta/lvl`). Bots pause 0.6–1.2 s. The hint uses the Средно bot's choice.
- Benchmark: `dart run tool/bench.dart 100 <easy|medium|me|he|hm>` (seeded matches, sides swapped).

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
│   ├── lobby/       # (placeholder)
│   ├── multiplayer/ # (placeholder)
│   ├── online/      # Online entry, lobby, waiting screen, room table
│   └── settings/    # Theme toggle (persisted)
├── online/          # Db abstraction, room logic, host driver, room client
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

Font: Comfortaa (bundled static weights 300–700 instanced from the Google Fonts variable font; SIL Open Font License, see `assets/fonts/Comfortaa-OFL.txt`).
