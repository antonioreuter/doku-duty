/// The two facts about a candidate that storage must keep.
///
/// Pure Dart. Both distinctions exist from day one because adding either later
/// means migrating live saved games (D-15), and D-33 makes those saves the thing
/// this whole layer is protecting.
library;

/// Which ink a candidate is written in.
///
/// The player sees the difference — indigo against turquoise-and-underlined
/// (D-73) — and one action clears every provisional mark at once (D-11).
enum NoteKind { settled, provisional }

/// Where a candidate came from.
///
/// Invisible to the player: generated and manual notes render identically
/// (D-15). Undo, **auto-cleanup**, and "clear notes" all need the provenance,
/// which is why it is stored rather than inferred.
enum NoteOrigin { manual, generated }
