import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../persistence/application/database_provider.dart';
import '../data/stamp_repository.dart';

final stampRepositoryProvider = Provider<StampRepository>(
  (ref) => StampRepository(ref.watch(appDatabaseProvider)),
);

/// The player's **stamp**s, summed from their **earning**s on every read
/// (D-133). Shown in the **cabinet** and nowhere else (D-134).
final stampBalanceProvider = FutureProvider<int>(
  (ref) => ref.watch(stampRepositoryProvider).balance(),
);
