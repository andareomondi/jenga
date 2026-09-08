import 'package:intl/intl.dart';
import 'package:jenga/presentation/screens/diagonistic_screen.dart'; // Keep your exact path

enum TowerEventType { added, removed, softTap, handPlaced, unknown }

class TowerEvent {
  final TowerEventType type;
  final int countDelta;
  final int newCount;
  final String rawMessage;
  final DateTime timestamp;

  const TowerEvent({
    required this.type,
    required this.countDelta,
    required this.newCount,
    required this.rawMessage,
    required this.timestamp,
  });

  factory TowerEvent.fromString(String raw) {
    final cleanString = raw.trim();
    final lowerString = cleanString.toLowerCase();
    final now = DateTime.now();

    // 1. Match specific string events without counts
    if (lowerString.contains('hand placed')) {
      return TowerEvent(
        type: TowerEventType.handPlaced,
        countDelta: 0,
        newCount: -1, // -1 means count unchanged
        rawMessage: cleanString,
        timestamp: now,
      );
    }

    if (lowerString.contains('soft tap detected')) {
      return TowerEvent(
        type: TowerEventType.softTap,
        countDelta: 0,
        newCount: -1,
        rawMessage: cleanString,
        timestamp: now,
      );
    }

    // 2. Match Removed
    final removedMatch = RegExp(
      r'blocks\s+removed:\s*(\d+)\.\s*New\s+Count:\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(cleanString);

    if (removedMatch != null) {
      return TowerEvent(
        type: TowerEventType.removed,
        countDelta: int.tryParse(removedMatch.group(1) ?? '1') ?? 1,
        newCount: int.tryParse(removedMatch.group(2) ?? '0') ?? 0,
        rawMessage: cleanString,
        timestamp: now,
      );
    }

    // 3. Match Added
    final addedMatch = RegExp(
      r'blocks\s+added:\s*(\d+)\.\s*New\s+Count:\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(cleanString);

    if (addedMatch != null) {
      return TowerEvent(
        type: TowerEventType.added,
        countDelta: int.tryParse(addedMatch.group(1) ?? '1') ?? 1,
        newCount: int.tryParse(addedMatch.group(2) ?? '0') ?? 0,
        rawMessage: cleanString,
        timestamp: now,
      );
    }

    return TowerEvent(
      type: TowerEventType.unknown,
      countDelta: 0,
      newCount: -1,
      rawMessage: cleanString,
      timestamp: now,
    );
  }

  static List<TowerEvent> parseStreamChunk(String chunk) {
    final lines = chunk.split(RegExp(r'[\r\n]+'));
    final events = <TowerEvent>[];

    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        events.add(TowerEvent.fromString(line));
      }
    }
    return events;
  }

  DiagEvent toDiagEvent() {
    late DiagEventType diagType;
    switch (type) {
      case TowerEventType.added:
        diagType = DiagEventType.added;
        break;
      case TowerEventType.removed:
        diagType = DiagEventType.removed;
        break;
      case TowerEventType.softTap:
        diagType = DiagEventType.softTap;
        break;
      case TowerEventType.handPlaced:
        diagType = DiagEventType.handPlaced;
        break;
      case TowerEventType.unknown:
        diagType = DiagEventType.softTap; // Fallback for unknown
        break;
    }

    // Only show counts in detail if the event has count data
    final detailText = newCount >= 0
        ? 'Count: $newCount (${type == TowerEventType.added ? '+' : '-'}$countDelta)'
        : rawMessage;

    return DiagEvent(
      type: diagType,
      detail: detailText,
      time: DateFormat('HH:mm:ss.SS').format(timestamp),
    );
  }
}
