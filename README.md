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

## Beta 5 — sound and feel
- Animated deal (`widgets/table_effects.dart`): card backs fly from the dealer counter-clockwise in belot order
  (3 + 2 each, then 3 each after the contract), staggered 70 ms; the player's cards fan into the hand as they
  land. Won tricks slide off toward the winner. Driven only by consecutive table states, so online clients
  animate the same deal without extra messages; a client that (re)joins mid-deal just shows the cards. Input is
  disabled while dealing and the drivers (offline controller, online host) hold bots for the animation
  (`core/constants/deal_timing.dart`). Reduced motion (OS setting) skips the flights.
- Sound (`features/feedback/sound.dart`, `audioplayers`): soft deal swish, card tap, trick collect, quiet
  your-turn chime, declaration and belot tones, distinct contra/recontra, deal made/failed, match won/lost.
  Pooled players so rapid cards overlap cleanly; mixes with other audio and respects the iOS silent switch; on
  the web audio unlocks on the first tap.
- Haptics on mobile: light on your plays and bids, medium on tricks your team wins and deal results, heavy on
  contra/recontra and the match result.
- Settings → **Звук и усещане**: Sound and Haptics toggles (persisted).
- All sounds are synthesized by `tool/make_sounds.py` (numpy, 22 kHz mono WAV, ~290 KB total) and released as
  CC0 — see `assets/sounds/LICENSE.md`. Regenerate with `python3 tool/make_sounds.py`.

## Beta 6 — score sheet and deal recap
- Score sheet (`widgets/score_sheet.dart`): the paper "Ние / Вие" sheet in the app's style — one row per deal
  with the points written and a running total, the contract badge in the middle (declarer's team colour, ×2/×4
  for contra/recontra) and markers (вкарана, висяща, капо, контра, hanging points left/awarded), totals under a
  double line. Opens from the sheet button next to the score (or tapping the score) and follows live state
  (online: the host's state); shown at match end.
- Last trick: the round button in the corner of the table shows the previous trick (who played what, who took
  it); any tap closes it.
- Deal recap (`widgets/deal_result_panel.dart`): animated breakdown — cards, last 10, declarations, belot,
  No Trump ×2, valat, total, outcome (изкарана / вкарана / висяща, contra/recontra), the points written and
  hanging points — counting up line by line; tap to skip; reduced motion shows it at once. Numbers come from the
  engine (`DealScoreBreakdown` in `core/rules/scoring.dart`), tested against the engine on hundreds of deals.
- Screenshots/dev only: `flutter build web --dart-define=DEMO_AUTOPLAY_MS=600` speeds up auto-play and bots.

## Beta 7 — emotes
- The top score now waits for the deal recap to finish counting (or a tap to skip) before it updates.
- Emotes in online games (`lib/features/emotes/`): the round button at the bottom-left of the table opens a
  compact picker with 8 animated reactions (👏 😂 😮 😤 👍 🙏 🤔 🔥) and 4 quick phrases (Браво!, Хайде!, Упс!,
  Добра игра). The emote pops over the sender's avatar for everyone for ~2.5 s, then fades. There is no 🤖, which
  is reserved for bots. Bots don't emote, and offline games don't show the button.
- Sync: `rooms/$code/emotes/$uid = {e, t}`. Only the sender can write it, `t` must be the server time, and the
  ids are whitelisted. The rules allow one emote per 2 s per player (`now >= previous t + 2000`), and the client
  waits 2.2 s between sends. The node is removed when the player leaves and is deleted with the room.
- Settings → Емоции: hide other players' emotes. Your own emotes are still shown.
- Animated emoji: [Noto Emoji Animation](https://googlefonts.github.io/noto-emoji-animation/) by Google,
  licensed **CC BY 4.0**. They are bundled offline as 96 px animated WebP (`tool/make_emotes.py`); see
  `assets/emotes/LICENSE.md`.

## Beta 8 — profile
- Bot names never match a human at the table (trimmed, case-insensitive), online and offline. Each seat keeps its
  usual name (Иван, Ники, Мария, Петър) unless a human has it; then the bot takes the next free plain name from
  `botNamePool` (Стефан, Елена, Димитър…). Every client computes the same names (`pickBotNames` in
  `core/agents/bot_names.dart`).
- Profile (`lib/features/profile/profile_screen.dart`). Open it from the avatar or greeting on home, the stats
  card, or Settings → Профил и статистика. It shows:
  - a large avatar with an edit pencil and the name below it, editable with the same validation as the name prompt;
  - stat tiles for games, wins, win rate, current and best win streak, deals, contracts made % and valats;
  - filters: all, offline (all levels or a single difficulty), online.
- Avatars: 24 emoji in the same style as the table avatars. 🤖 is never offered and is rejected everywhere
  (`sanitizeAvatar`). The chosen avatar is stored locally, shown at the table and in lobbies, and synced as
  `rooms/$code/members/$uid/a`. The database rules require a short string without 🤖.
- Stats are kept per bucket (all / offline / offline per difficulty / online) in `player_stats_v2`, so streaks are
  exact for each split. Old offline stats are migrated. Online deals count from the moment you sit down.
- Match history: the last 50 finished matches, newest first, stored in shared preferences (`match_history_v1`,
  one JSON string). Each entry has the date and time (device local time), mode (offline difficulty or online
  room), names on both teams, final score, win or loss, and the per-deal rows, so tapping it reopens that match's
  Ние/Вие score sheet.

## Beta 9 — installable web app, smooth deal, swoosh
- **Install (PWA)** from https://b0zhkov.github.io/bulgarian_bridge_belotte_app/ on Android (Chrome: *Инсталирай*
  on home, the browser's own dialog) and iOS (Safari: *Как?* → Сподели → Добави към началния екран). Never shown
  when running installed (display-mode standalone / `navigator.standalone`); dismissal is remembered.
  `web/manifest.json` (Белот, standalone, portrait, black theme/background, scope and start_url
  `/bulgarian_bridge_belotte_app/`), icons drawn by `tool/make_icons.py` (any, maskable, apple-touch-icon,
  favicon), iOS meta tags in `web/index.html`.
- **Service worker** `web/sw.js`, filled in after the web build by `tool/make_sw.py` (CI does this): a version
  hash of the build and the app-shell precache. Cache-first per version, so loads are instant and offline play
  works; CanvasKit/fonts are cached on first use. A new release installs a new worker: the home screen shows
  *Има нова версия — Обнови*, otherwise it is applied on the next launch; old caches are deleted. The app checks
  for updates whenever it returns to the foreground. JS glue is `window.belotPwa` (index.html), Dart side in
  `lib/features/pwa/`.
- **Deal lag fixed.** Cause: the deal started on the very first frame of the table page, while the page was still
  transitioning in, and those first frames were very slow to paint (first use of card shaders, text, emoji
  font). The animation clock ran on wall time, so the pile sat frozen during the stall and the cards then
  jumped. Now (a) `TableWarmUp` paints the table's cards, emoji and fonts once at app start under the home
  screen; (b) the deal waits for the page transition to finish; (c) the deal clock advances at most 50 ms per
  frame, so a slow frame never makes cards jump. Measured in headless Chrome (software GL), tap → deal:
  before, the first card moved 435 ms after the deal start and had already skipped 350 ms of flight (frame gaps
  343/178/159/209 ms). After, every flight starts from 0 (first step 33 ms); worst frame during the deal
  is about 110 ms; the route-in frames happen before the deal. Build with `--dart-define=PERF_LOG=true` to log
  frame timings (`core/perf/perf_log.dart`).
- **Sound**: a swoosh when any seat plays a card, started by the card's flight to the table
  (`widgets/trick_area.dart`; plays that arrive together online fly 110 ms apart, each with its swoosh). The deal
  and match result sounds are kept; all other effects were removed. The player is created and its pools
  preloaded at app start, and on the web every voice is unlocked by the first tap. Haptics are unchanged.

## Beta 10 — invite links, last trick and score details
- **Покани** (lobby code card and next to the in-game code) opens the native share sheet (`share_plus` on
  Android/iOS, Web Share API in browsers that have it) with the text and
  `https://b0zhkov.github.io/bulgarian_bridge_belotte_app/?room=CODE`; where there is no share sheet (desktop
  browsers) the invite is copied with a toast. Tapping the code itself still copies.
- **Opening an invite link** (web / installed PWA): first launch asks for the name, then the app goes straight to
  joining that room with the usual rules (team pick in the lobby, waiting screen mid-game). A closed or unknown
  room, or a broken code, shows *Поканата не може да се отвори* with the reason, the code filled in and
  *Създай стая* still available. `?room=` is removed from the address bar once handled, so a reload does not
  join again. The Android APK shares the same link (opens the web app); no APK deep link (Android App Links
  would need `assetlinks.json` at the domain root, which GitHub project pages cannot serve).
- **Last trick** (button in the trick area during play, offline and online): who played what and who took it,
  plus the trick's points. It closes on tap, or by itself when the next card is played or the deal ends. Online
  it uses the public trick list only (no new data, no rule changes).
- **Score details**: tap a deal in the Ние/Вие sheet (in game and at match end) for its breakdown — contract
  and who played it, card points, last 10, each declaration (терца/кварта/квинта with suit and top card, каре)
  in its owner's column with the owner's name, белот per team, Без коз ×2, капо, raw totals, the outcome
  (изкарана/вкарана/висяща, контра/реконтра ×2/×4) and the belot.bg rounding in words (e.g.
  *Ние 96 → 9 · Вие 66 → 7*, *Общо 162 → 16 ×2 = 32 за Ние*), then the points written and hanging points. The
  deal recap shows the same per-declaration lines and the rounding. Rounding display is recomputed by
  `DealScoreRounding` and tested against the engine on random deals.

## Beta 11 — rejoin, quick match, rating, achievements, table styles

* **Rejoin your seat.** When a player drops (or leaves during a match) a bot
  takes over at once, but the seat stays *reserved* for their anonymous uid
  until the match ends (`Seat.bot(heldFor: uid)`). Coming back by code, link
  or the home-screen card "Върни се в играта" (offered on launch while a
  reserved seat exists) gives the seat back immediately, mid-deal included; a
  bot that is already thinking finishes its move. Newcomers only take free
  (unreserved) bot seats at the end of a deal. Leaving asks for confirmation
  and keeps the reservation (the member entry stays, offline). A room where
  only absent players and bots remain closes as before; after the match the
  reservations are gone and the normal lobby / quick-match flow applies.
* **Бърза игра (quick match).** `queue/{uid}` entries with a server-time
  heartbeat (5 s) and an onDisconnect delete; entries without a heartbeat in
  the last 20 s are ignored. The oldest waiting player is the matchmaker: at
  4 players, or when its 30 s are up, it creates a quick room (`meta/qm`),
  claims itself and then each other player with an RTDB transaction on
  `queue/{uid}/room` (a player can only be claimed once; rules only let the
  host of a quick room claim). A player waiting 40 s takes over if the
  matchmaker went silent. Claimed players join that room; seats are random
  (random teams), missing places are bots, and a claimed player who has not
  connected after 8 s gets a reserved seat. Quick rooms have no code/invite
  UI; after the match: "Нова бърза игра" or "Начало".
* **Rating (quick matches only).** Start 1000, team Elo with K = 32: team
  rating = average of its two seats, **bots count as 1000**;
  `E = 1/(1+10^((Ropp−Rteam)/400))`, `Δ = round(32·(S−E))`, the same Δ for both
  partners. Only humans still seated and online at the end are rated — a
  player who dropped and did not return is not changed (no penalty).
  Ranks: Новак < 900 ≤ Бронз < 1050 ≤ Сребро < 1200 ≤ Злато < 1350 ≤ Платина
  < 1500 ≤ Диамант < 1700 ≤ Майстор. The host writes
  `qresults/{room}/{matchId}/{uid} = {b, d}` once; each player then writes
  `ratings/{uid} = {r: b + d, g, c, x, t}` and deletes the used result.
  Rules: results only from the host of a quick room that is ≥ 2 min old,
  |d| ≤ 32, `b` = the player's stored rating, write-once; a rating must equal
  `b + d` of an existing result for that uid, `t` is server time and at most
  one update per 2 min; a rating can only be removed (reset to 1000) when it
  is ≥ 1000. **Residual risk:** clients are trusted as hosts, so a player can
  create their own quick room, wait 2 min and award themselves up to +32
  every 2 minutes (or a malicious host can give others −32). A real fix
  needs server-side scoring (Cloud Functions).
* **16 achievements** (local, so they work offline; merged into
  `ach/{uid}` when online): Първа победа, 10/50/100 победи, Капо, Белот!,
  Каре, Квинта, Без коз, Всичко коз, Контра на място, Реконтра, Обрат (win
  after trailing by 50+), Срещу трудните (beat hard bots), Първа бърза игра,
  Златен ранг. Shown in the profile (locked/unlocked); an unlock shows a
  small silent toast — no new sounds.
* **Table and language.** Settings → card back (Класически, Нощ, Гора,
  Минимал) and table colour (Класическа, Сукно, Бордо, Графит; each with a
  dark and light variant that keeps blue = us / orange = them readable),
  stored locally. Full English translation with a language switch; the app
  always starts in Bulgarian (the device locale is ignored). Card ranks use
  the same Latin letters (A K Q J 10 9 8 7) in both languages, as before.
* Rules checks: `scripts/rules_check.py` (in the workspace) covers queue,
  ratings, results and achievements too.

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
flutter build web        # build/web (then: python3 tool/make_sw.py)
flutter build apk        # build/app/outputs/flutter-apk/app-release.apk
```
The table can be opened directly at `/#/game` on web.

Font: Comfortaa (bundled static weights 300–700 instanced from the Google Fonts variable font; SIL Open Font License, see `assets/fonts/Comfortaa-OFL.txt`).
