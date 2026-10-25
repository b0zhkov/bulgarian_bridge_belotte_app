import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/rating.dart';
import '../settings/settings_controller.dart';

/// The player's own quick-match rating, cached locally (the database copy
/// in `ratings/{uid}` is the source of truth and refreshes this cache).
class MyRatingController extends Notifier<Rating> {
  static const _key = 'rating_v1';

  @override
  Rating build() {
    try {
      final raw = ref.read(sharedPrefsProvider).getString(_key);
      if (raw != null) return Rating.fromMap(jsonDecode(raw));
    } catch (_) {}
    return Rating.initial;
  }

  void set(Rating r) {
    state = r;
    ref
        .read(sharedPrefsProvider)
        .setString(_key, jsonEncode({'r': r.value, 'g': r.games}));
  }

  void recordChange(RatingChange c) => set(Rating(c.after, state.games + 1));
}

final myRatingProvider = NotifierProvider<MyRatingController, Rating>(
  MyRatingController.new,
);
