import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/room_logic.dart';
import '../../online/room_models.dart';
import '../settings/settings_controller.dart';
import 'online_controller.dart';

/// On launch (and whenever this player is not in a room): the code of a
/// running match that still holds a seat for this player, if any. A stale
/// entry (match over, room closed, seat gone) is forgotten.
final resumeOfferProvider = FutureProvider<String?>((ref) async {
  final inRoom = ref.watch(
    onlineControllerProvider.select((s) => s.client != null),
  );
  if (inRoom) return null;
  final prefs = ref.read(sharedPrefsProvider);
  final code = prefs.getString(OnlineController.activeRoomKey);
  if (code == null) return null;
  try {
    final db = await ref.read(dbConnectorProvider)();
    final meta = RoomMeta.fromMap(await db.get('rooms/$code/meta'));
    if (meta == null ||
        meta.onlineCount <= 0 ||
        meta.status != RoomStatus.playing) {
      await prefs.remove(OnlineController.activeRoomKey);
      return null;
    }
    final seats = Seat.decodeAll(await db.get('rooms/$code/seats'));
    if (!RoomLogic.hasSeat(seats, db.uid)) {
      await prefs.remove(OnlineController.activeRoomKey);
      return null;
    }
    return code;
  } catch (_) {
    return null;
  }
});

/// "Not now" on the resume card (until the next launch).
class ResumeDismissed extends Notifier<String?> {
  @override
  String? build() => null;
  void dismiss(String code) => state = code;
}

final resumeDismissedProvider = NotifierProvider<ResumeDismissed, String?>(
  ResumeDismissed.new,
);
