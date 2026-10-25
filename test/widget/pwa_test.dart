import 'package:bulgarian_bridge_belotte_app/features/pwa/pwa_bridge.dart';
import 'package:bulgarian_bridge_belotte_app/features/pwa/pwa_controller.dart';
import 'package:bulgarian_bridge_belotte_app/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' as app;
import 'fakes.dart';

/// Stands in for `window.belotPwa`.
class FakePwaBridge implements PwaBridge {
  FakePwaBridge({
    this.isStandalone = false,
    this.isIosSafari = false,
    this.canPrompt = false,
    this.updateReady = false,
  });

  @override
  bool isStandalone;
  @override
  bool isIosSafari;
  @override
  bool canPrompt;
  @override
  bool updateReady;
  int prompts = 0, updates = 0;
  final _listeners = <void Function()>[];

  void changed() {
    for (final f in _listeners) {
      f();
    }
  }

  @override
  Future<String> promptInstall() async {
    prompts++;
    canPrompt = false;
    return 'accepted';
  }

  @override
  void applyUpdate() => updates++;

  @override
  void onChange(void Function() listener) => _listeners.add(listener);
}

void main() {
  setUp(() => app.sound = FakeSoundPlayer());

  Future<FakePwaBridge> pump(
    WidgetTester t,
    FakePwaBridge b, {
    Map<String, Object> prefs = const {'player_name': 'Георги'},
  }) async {
    await app.pumpApp(
      t,
      prefs: prefs,
      overrides: [pwaBridgeProvider.overrideWithValue(b)],
    );
    await t.pumpAndSettle();
    return b;
  }

  testWidgets('native / unsupported browser: no hints', (t) async {
    await pump(t, FakePwaBridge());
    expect(find.byKey(const Key('pwa-install')), findsNothing);
    expect(find.byKey(const Key('pwa-update')), findsNothing);
  });

  testWidgets('Android/Chrome: install button opens the browser prompt', (
    t,
  ) async {
    final b = await pump(t, FakePwaBridge(canPrompt: true));
    expect(find.byKey(const Key('pwa-install')), findsOneWidget);
    expect(find.text('Инсталирай'), findsOneWidget);
    await t.tap(find.byKey(const Key('pwa-install-action')));
    await t.pumpAndSettle();
    expect(b.prompts, 1);
    // Accepted: the browser no longer offers it, so the hint goes away.
    expect(find.byKey(const Key('pwa-install')), findsNothing);
  });

  testWidgets('prompt offered later (beforeinstallprompt) shows the hint', (
    t,
  ) async {
    final b = await pump(t, FakePwaBridge());
    expect(find.byKey(const Key('pwa-install')), findsNothing);
    b
      ..canPrompt = true
      ..changed();
    await t.pumpAndSettle();
    expect(find.byKey(const Key('pwa-install')), findsOneWidget);
  });

  testWidgets('iOS Safari: instructions Share → Add to Home Screen', (t) async {
    await pump(t, FakePwaBridge(isIosSafari: true));
    expect(find.text('Как?'), findsOneWidget);
    await t.tap(find.byKey(const Key('pwa-install-action')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('ios-install-sheet')), findsOneWidget);
    expect(find.textContaining('Сподели'), findsOneWidget);
    expect(find.textContaining('Добави към началния екран'), findsOneWidget);
  });

  testWidgets('never shown when already installed (standalone)', (t) async {
    await pump(
      t,
      FakePwaBridge(isStandalone: true, canPrompt: true, isIosSafari: true),
    );
    expect(find.byKey(const Key('pwa-install')), findsNothing);
  });

  testWidgets('dismissal is remembered', (t) async {
    await pump(t, FakePwaBridge(canPrompt: true));
    await t.tap(find.byKey(const Key('pwa-install-close')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('pwa-install')), findsNothing);
    final c = await app.pumpApp(
      t,
      overrides: [
        pwaBridgeProvider.overrideWithValue(FakePwaBridge(canPrompt: true)),
      ],
      prefs: {'player_name': 'Георги', PwaController.dismissedKey: true},
    );
    await t.pumpAndSettle();
    expect(
      c.read(sharedPrefsProvider).getBool(PwaController.dismissedKey),
      isTrue,
    );
    expect(find.byKey(const Key('pwa-install')), findsNothing);
  });

  testWidgets('new version: banner, and Обнови applies it', (t) async {
    final b = await pump(t, FakePwaBridge());
    expect(find.byKey(const Key('pwa-update')), findsNothing);
    b
      ..updateReady = true
      ..changed();
    await t.pumpAndSettle();
    expect(find.text('Има нова версия'), findsOneWidget);
    await t.tap(find.byKey(const Key('pwa-update-now')));
    expect(b.updates, 1);
  });
}
