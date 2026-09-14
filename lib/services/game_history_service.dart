import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jenga/presentation/screens/score_board_screen.dart';

/// Service to persist game history and calculate real-time lifetime player stats.
class GameHistoryService {
  static const String _historyKey = 'jenga_game_history_v1';

  /// Save a completed game to local history storage
  static Future<void> saveGameRecord({
    required List<ScoreboardPlayer> finalPlayers,
    required String? winnerName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];

    final now = DateTime.now();
    final dateFormatted = _formatDate(now);

    final record = {
      'date': dateFormatted,
      'timestamp': now.toIso8601String(),
      'winnerName': winnerName ?? finalPlayers.first.name,
      'players': finalPlayers
          .map(
            (p) => {
              'name': p.name,
              'points': p.points,
              'blocksRemoved': p.blocksRemoved,
              'challenges': p.challenges,
            },
          )
          .toList(),
    };

    historyJson.insert(0, jsonEncode(record)); // Prepend newest first
    await prefs.setStringList(_historyKey, historyJson);
  }

  /// Retrieve all game history entries formatted for [GameHistoryScreen]
  static Future<List<HistoryEntry>> getGameHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];

    return historyJson.map((item) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      final players = (map['players'] as List).cast<Map<String, dynamic>>();

      // Build summary score string e.g. "120–95" or top player point
      final topScore = players.first['points'];
      final secondScore = players.length > 1 ? players[1]['points'] : 0;
      final scoreString = players.length > 1
          ? '$topScore–$secondScore'
          : '$topScore pts';

      return HistoryEntry(
        date: map['date'] as String? ?? 'Recent',
        winnerName: map['winnerName'] as String? ?? 'Winner',
        score: scoreString,
      );
    }).toList();
  }

  /// Compute real lifetime statistics for a specific player by name
  static Future<PlayerLifetimeStats> getStatsForPlayer(
    String playerName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];

    int gamesPlayed = 0;
    int gamesWon = 0;
    int totalBlocks = 0;
    int totalChallenges = 0;
    int bestScore = 0;

    for (final item in historyJson) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      final players = (map['players'] as List).cast<Map<String, dynamic>>();

      final playerMatch = players.firstWhere(
        (p) => (p['name'] as String).toLowerCase() == playerName.toLowerCase(),
        orElse: () => {},
      );

      if (playerMatch.isNotEmpty) {
        gamesPlayed++;
        final points = playerMatch['points'] as int? ?? 0;
        final blocks = playerMatch['blocksRemoved'] as int? ?? 0;
        final challenges = playerMatch['challenges'] as int? ?? 0;

        totalBlocks += blocks;
        totalChallenges += challenges;
        if (points > bestScore) bestScore = points;

        if ((map['winnerName'] as String).toLowerCase() ==
            playerName.toLowerCase()) {
          gamesWon++;
        }
      }
    }

    return PlayerLifetimeStats(
      gamesPlayed: gamesPlayed,
      gamesWon: gamesWon,
      blocksRemoved: totalBlocks,
      challenges: totalChallenges,
      bestScore: bestScore,
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
