import 'dart:js_interop';

import 'web_bridge.dart';

@JS('navigator')
external _Navigator get _navigator;

extension type _Navigator._(JSObject _) implements JSObject {
  external JSFunction? get share;
  @JS('share')
  external JSPromise<JSAny?> callShare(_ShareData data);
}

extension type _ShareData._(JSObject _) implements JSObject {
  external factory _ShareData({String title, String text});
}

@JS('history')
external _History get _history;

extension type _History._(JSObject _) implements JSObject {
  external void replaceState(JSAny? data, String unused, String url);
}

@JS('location')
external _Location get _location;

extension type _Location._(JSObject _) implements JSObject {
  external String get href;
}

Future<ShareOutcome> webShare({
  required String title,
  required String text,
}) async {
  try {
    if (_navigator.share == null) return ShareOutcome.unavailable;
    await _navigator.callShare(_ShareData(title: title, text: text)).toDart;
    return ShareOutcome.shared;
  } catch (e) {
    // The player closed the sheet: nothing else to do.
    if (e.toString().contains('AbortError')) return ShareOutcome.shared;
    return ShareOutcome.unavailable;
  }
}

void clearInviteFromUrl() {
  try {
    final uri = Uri.parse(_location.href);
    if (!uri.queryParameters.containsKey('room')) return;
    final q = Map.of(uri.queryParameters)..remove('room');
    final query = q.isEmpty ? '' : '?${Uri(queryParameters: q).query}';
    final frag = uri.hasFragment ? '#${uri.fragment}' : '';
    final s = '${uri.path}$query$frag';
    _history.replaceState(null, '', s);
  } catch (_) {}
}
