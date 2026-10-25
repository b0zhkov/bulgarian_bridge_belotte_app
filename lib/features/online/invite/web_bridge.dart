import 'invite_web_stub.dart'
    if (dart.library.js_interop) 'invite_web.dart'
    as impl;

/// Outcome of a native / Web Share attempt.
enum ShareOutcome {
  /// The share sheet was shown (and used or closed by the player).
  shared,

  /// No share sheet here: fall back to copying.
  unavailable,
}

/// Web Share API (`navigator.share`) where the browser has it; native builds
/// and browsers without it return [ShareOutcome.unavailable].
Future<ShareOutcome> webShare({required String title, required String text}) =>
    impl.webShare(title: title, text: text);

/// Removes `?room=` from the address bar after an invite link was handled,
/// so a reload does not join the room again. No-op off the web.
void clearInviteFromUrl() => impl.clearInviteFromUrl();
