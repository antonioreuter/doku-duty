import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';

/// The router, built once for the life of the app.
final routerProvider = Provider<GoRouter>((ref) {
  final router = createRouter();
  ref.onDispose(router.dispose);
  return router;
});
