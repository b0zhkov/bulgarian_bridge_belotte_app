import 'web_bridge.dart';

Future<ShareOutcome> webShare({
  required String title,
  required String text,
}) async => ShareOutcome.unavailable;

void clearInviteFromUrl() {}
