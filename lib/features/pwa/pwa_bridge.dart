import 'pwa_bridge_stub.dart'
    if (dart.library.js_interop) 'pwa_bridge_web.dart'
    as impl;

/// What the page (web/index.html, `window.belotPwa`) knows about
/// installing and updating the web app. Native builds get [NoPwaBridge].
abstract class PwaBridge {
  /// Running as an installed app (display-mode standalone).
  bool get isStandalone;

  /// iOS Safari: no install prompt, the user adds it via Share.
  bool get isIosSafari;

  /// The browser offered an install prompt (Android / desktop Chrome).
  bool get canPrompt;

  /// A new version is downloaded and waiting.
  bool get updateReady;

  /// Shows the browser's install dialog: 'accepted', 'dismissed' or
  /// 'unavailable'.
  Future<String> promptInstall();

  /// Activates the waiting version (the page reloads).
  void applyUpdate();

  /// Called whenever any of the above may have changed.
  void onChange(void Function() listener);
}

class NoPwaBridge implements PwaBridge {
  const NoPwaBridge();
  @override
  bool get isStandalone => false;
  @override
  bool get isIosSafari => false;
  @override
  bool get canPrompt => false;
  @override
  bool get updateReady => false;
  @override
  Future<String> promptInstall() async => 'unavailable';
  @override
  void applyUpdate() {}
  @override
  void onChange(void Function() listener) {}
}

PwaBridge createPwaBridge() => impl.createPwaBridge();
