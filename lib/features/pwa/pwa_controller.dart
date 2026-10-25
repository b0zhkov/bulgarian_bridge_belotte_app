import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';
import 'pwa_bridge.dart';

/// How the home screen offers installing the web app.
enum InstallHint {
  /// Nothing to offer (native app, already installed, unsupported browser,
  /// or dismissed).
  none,

  /// Android / desktop Chrome: a button that opens the install dialog.
  prompt,

  /// iOS Safari: short instructions (Share → Add to Home Screen).
  iosInstructions,
}

class PwaState {
  const PwaState({this.install = InstallHint.none, this.updateReady = false});
  final InstallHint install;
  final bool updateReady;
}

final pwaBridgeProvider = Provider<PwaBridge>((ref) => createPwaBridge());

class PwaController extends Notifier<PwaState> {
  static const dismissedKey = 'pwa_install_dismissed';
  bool _listening = false;

  @override
  PwaState build() {
    final bridge = ref.watch(pwaBridgeProvider);
    if (!_listening) {
      _listening = true;
      bridge.onChange(() {
        if (ref.mounted) state = _compute(bridge);
      });
    }
    return _compute(bridge);
  }

  PwaState _compute(PwaBridge b) {
    final dismissed =
        ref.read(sharedPrefsProvider).getBool(dismissedKey) ?? false;
    final InstallHint hint;
    if (b.isStandalone || dismissed) {
      hint = InstallHint.none;
    } else if (b.canPrompt) {
      hint = InstallHint.prompt;
    } else if (b.isIosSafari) {
      hint = InstallHint.iosInstructions;
    } else {
      hint = InstallHint.none;
    }
    return PwaState(install: hint, updateReady: b.updateReady);
  }

  Future<void> install() async {
    final b = ref.read(pwaBridgeProvider);
    await b.promptInstall();
    if (ref.mounted) state = _compute(b);
  }

  void dismissInstall() {
    ref.read(sharedPrefsProvider).setBool(dismissedKey, true);
    state = _compute(ref.read(pwaBridgeProvider));
  }

  void applyUpdate() => ref.read(pwaBridgeProvider).applyUpdate();
}

final pwaProvider = NotifierProvider<PwaController, PwaState>(
  PwaController.new,
);
