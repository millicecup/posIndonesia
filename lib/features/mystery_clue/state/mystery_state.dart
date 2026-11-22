import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unlocks the collection detail for this app session, independently of stamps.
final mysterySolvedPoiIdsProvider = StateProvider<Set<String>>((ref) => {});
