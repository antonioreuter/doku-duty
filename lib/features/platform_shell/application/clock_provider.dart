import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the app believes the time is.
///
/// Exists so that anything *rendered* from the clock can be pinned in a test.
/// A widget calling `DateTime.now()` directly is untestable in the way that
/// matters here: a golden capturing "42 days left" is capturing the day it was
/// generated on, so it passes that afternoon and fails the next morning, for a
/// whole year, for no reason anyone reading the diff would guess. A test that
/// fails daily gets ignored, and an ignored golden has stopped guarding
/// anything.
///
/// **For display, not for records.** A stored `updatedAt` stamp still takes
/// `DateTime.now()` at the point of writing — those are facts about when a row
/// was written and have no business being overridable. This is for values a
/// player reads off the screen.
///
/// The **daily challenge** does not use this. Dates there come from
/// `DailyClock`, which carries the server-time offset and the verified flag
/// that `docs/TECH_STACK.md` §3b requires; a bare wall clock is exactly what it
/// is not allowed to trust.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);
