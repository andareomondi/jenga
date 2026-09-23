import 'package:flutter/material.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/ui/player_components.dart';
import 'package:jenga/presentation/widgets/buttons.dart';
import 'package:jenga/services/game_history_service.dart';

class ScoreboardPlayer {
  const ScoreboardPlayer({
    required this.name,
    required this.points,
    required this.blocksRemoved,
    required this.challenges,
  });
  final String name;
  final int points;
  final int blocksRemoved;
  final int challenges;
}

/// Current-game scoreboard tab with wired dynamic history & lifetime stats.
class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({
    super.key,
    required this.players,
    this.onPlayerTap,
    this.onViewHistory,
  });

  final List<ScoreboardPlayer> players; // pre-sorted by rank
  final ValueChanged<ScoreboardPlayer>? onPlayerTap;
  final VoidCallback? onViewHistory;

  void _handlePlayerTap(BuildContext context, ScoreboardPlayer player) async {
    if (onPlayerTap != null) {
      onPlayerTap!(player);
      return;
    }

    // Dynamic fetch from persistent local storage
    final stats = await GameHistoryService.getStatsForPlayer(player.name);

    if (context.mounted) {
      showPlayerStatsSheet(context, name: player.name, stats: stats);
    }
  }

  void _handleViewHistory(BuildContext context) async {
    if (onViewHistory != null) {
      onViewHistory!();
      return;
    }

    // Dynamic fetch from persistent local storage
    final entries = await GameHistoryService.getGameHistory();

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameHistoryScreen(entries: entries)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Text('Scoreboard', style: AppText.display(size: 24)),
          const SizedBox(height: 14),
          for (var i = 0; i < players.length; i++) ...[
            ScoreCard(
              rank: i + 1,
              name: players[i].name,
              points: players[i].points,
              meta:
                  '${players[i].blocksRemoved} blocks · ${players[i].challenges} challenges',
              onTap: () => _handlePlayerTap(context, players[i]),
            ),
            if (i != players.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          Material(
            color: AppColors.feltPale,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _handleViewHistory(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'View local game history',
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.felt,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.felt,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerLifetimeStats {
  const PlayerLifetimeStats({
    required this.gamesPlayed,
    required this.gamesWon,
    required this.blocksRemoved,
    required this.challenges,
    required this.bestScore,
  });
  final int gamesPlayed;
  final int gamesWon;
  final int blocksRemoved;
  final int challenges;
  final int bestScore;
}

/// Secondary interaction reached by tapping a player on the scoreboard —
/// displays real aggregated lifetime statistics.
Future<void> showPlayerStatsSheet(
  BuildContext context, {
  required String name,
  required PlayerLifetimeStats stats,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.walnut.withOpacity(0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              PlayerAvatar(name: name, size: 44),
              const SizedBox(width: 12),
              Text(name, style: AppText.display(size: 22)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.9,
            children: [
              _statBox('${stats.gamesPlayed}', 'Games played'),
              _statBox('${stats.gamesWon}', 'Games won'),
              _statBox('${stats.blocksRemoved}', 'Blocks removed'),
              _statBox('${stats.challenges}', 'Challenges done'),
            ],
          ),
          const SizedBox(height: 12),
          _statBox('${stats.bestScore}', 'Best score', fullWidth: true),
          const SizedBox(height: 18),
          SecondaryButton(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

Widget _statBox(String value, String label, {bool fullWidth = false}) {
  return Container(
    width: fullWidth ? double.infinity : null,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppText.mono(size: 22, weight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppText.body(
            size: 11.5,
            weight: FontWeight.w500,
            color: AppColors.walnutSoft,
          ),
        ),
      ],
    ),
  );
}

class HistoryEntry {
  const HistoryEntry({
    required this.date,
    required this.winnerName,
    required this.score,
  });
  final String date;
  final String winnerName;
  final String score;
}

/// Local game history list screen — displays real records loaded from storage.
class GameHistoryScreen extends StatelessWidget {
  const GameHistoryScreen({super.key, required this.entries});
  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: BackButton(color: AppColors.walnut),
      ),
      body: SafeArea(
        child: entries.isEmpty
            ? Center(
                child: Text(
                  'No past games recorded yet.',
                  style: AppText.body(size: 15, color: AppColors.walnutSoft),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Text('Game History', style: AppText.display(size: 22)),
                  const SizedBox(height: 14),
                  for (final e in entries)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.date,
                                style: AppText.body(
                                  size: 11.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.walnutSoft,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${e.winnerName} won',
                                style: AppText.body(
                                  size: 14.5,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            e.score,
                            style: AppText.mono(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.felt,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
