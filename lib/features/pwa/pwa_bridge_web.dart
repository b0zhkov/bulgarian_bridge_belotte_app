import 'dart:js_interop';

import 'pwa_bridge.dart';

@JS('belotPwa')
external _BelotPwa? get _pwa;

extension type _BelotPwa._(JSObject _) implements JSObject {
  external bool isStandalone();
  external bool isIosSafari();
  external bool canPrompt();
  external bool updateReady();
  external JSPromise<JSString> promptInstall();
  external void applyUpdate();
  external void onChange(JSFunction listener);
}

class _WebPwaBridge implements PwaBridge {
  _WebPwaBridge(this._js);
  final _BelotPwa _js;

  @override
  bool get isStandalone => _js.isStandalone();
  @override
  bool get isIosSafari => _js.isIosSafari();
  @override
  bool get canPrompt => _js.canPrompt();
  @override
  bool get updateReady => _js.updateReady();
  @override
  Future<String> promptInstall() async =>
      (await _js.promptInstall().toDart).toDart;
  @override
  void applyUpdate() => _js.applyUpdate();
  @override
  void onChange(void Function() listener) => _js.onChange(listener.toJS);
}

PwaBridge createPwaBridge() {
  final js = _pwa;
  return js == null ? const NoPwaBridge() : _WebPwaBridge(js);
}
