import 'package:flutter/material.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/ui/player_components.dart';
import 'package:jenga/presentation/widgets/buttons.dart';
import 'package:jenga/presentation/widgets/jenga_tower.dart';

/// The big, celebratory game-over moment — this is the one place the UI is
/// allowed to be expressive. Feels like a highlight, not an error.
class TowerCollapseScreen extends StatelessWidget {
  const TowerCollapseScreen({
    super.key,
    required this.playerWhoCollapsedIt,
    required this.onViewResults,
    required this.onPlayAgain,
  });

  final String playerWhoCollapsedIt;
  final VoidCallback onViewResults;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.5,
          child: Center(child: JengaTower(fullLayers: 3, isCollapsed: true)),
        ),
        Container(color: AppColors.cream.withOpacity(0.92)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💥', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 14),
                Text(
                  'Tower Down!',
                  style: AppText.display(size: 28, color: AppColors.coral),
                ),
                const SizedBox(height: 8),
                Text(
                  '$playerWhoCollapsedIt caused the collapse.',
                  style: AppText.body(size: 14.5, color: AppColors.walnutSoft),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                PrimaryButton(label: 'View Results', onPressed: onViewResults),
                const SizedBox(height: 10),
                SecondaryButton(label: 'Play Again', onPressed: onPlayAgain),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ResultsPlayer {
  const ResultsPlayer(this.name, this.points);
  final String name;
  final int points;
}

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.winner,
    required this.summary,
    required this.ranked,
    required this.onPlayAgain,
    required this.onBackToHome,
  });

  final String winner;
  final String
  summary; // e.g. "120 points · 18 blocks removed · 4 challenges completed"
  final List<ResultsPlayer> ranked;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text('$winner wins!', style: AppText.display(size: 26)),
            const SizedBox(height: 6),
            Text(
              summary,
              style: AppText.body(size: 13.5, color: AppColors.walnutSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            Column(
              children: [
                for (var i = 0; i < ranked.length; i++) ...[
                  ScoreCard(
                    rank: i + 1,
                    name: ranked[i].name,
                    points: ranked[i].points,
                  ),
                  if (i != ranked.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Play Again', onPressed: onPlayAgain),
            const SizedBox(height: 6),
            GhostTextButton(label: 'Back to Home', onPressed: onBackToHome),
          ],
        ),
      ),
    );
  }
}
