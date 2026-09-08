import 'package:flutter/material.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/ui/player_components.dart';
import 'package:jenga/presentation/widgets/buttons.dart';
import 'package:jenga/presentation/widgets/jenga_tower.dart';

enum GamePhase { turn, blockRemoved, waitingPlacement, challengeActive }

class PlayScreen extends StatelessWidget {
  const PlayScreen({
    super.key,
    required this.currentPlayerName,
    required this.phase,
    required this.intactLayers,
    required this.totalBlockCount,
    this.isUnstable = false,
    this.errorMessage,
    this.onPause,
  });

  final String currentPlayerName;
  final GamePhase phase;
  final int intactLayers;
  final int totalBlockCount; // Dynamic block count from state
  final bool isUnstable;
  final String? errorMessage;
  final VoidCallback? onPause;

  int get _blocksRemaining => totalBlockCount;

  String get _instruction {
    switch (phase) {
      case GamePhase.turn:
        return 'Remove a block.';
      case GamePhase.blockRemoved:
        return 'Remove a block.';
      case GamePhase.waitingPlacement:
        return 'Place it on top.';
      case GamePhase.challengeActive:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PlayerAvatar(name: currentPlayerName),
                  RoundIconButton(
                    icon: Icons.pause_rounded,
                    onPressed: onPause,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (phase == GamePhase.blockRemoved)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: FeedbackChip(label: 'Block removed', icon: '✓'),
                    ),
                  if (errorMessage != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: FeedbackChip(label: errorMessage!, icon: '✕'),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isUnstable) ...[
                        const UnstableBanner(),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        "${currentPlayerName.toUpperCase()}'S TURN",
                        style: AppText.eyebrow(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _instruction,
                        style: AppText.body(
                          size: 15,
                          color: AppColors.walnutSoft,
                        ),
                      ),
                      const SizedBox(height: 24),
                      JengaTower(
                        fullLayers: intactLayers,
                        wobble: isUnstable,
                        placingTopLayer: phase == GamePhase.waitingPlacement,
                      ),
                      const SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          style: AppText.body(
                            size: 12.5,
                            color: AppColors.walnutSoft,
                          ),
                          children: [
                            TextSpan(
                              text: '$_blocksRemaining ',
                              style: AppText.body(
                                size: 12.5,
                                weight: FontWeight.w800,
                                color: AppColors.walnut,
                              ),
                            ),
                            const TextSpan(text: 'blocks remaining'),
                          ],
                        ),
                      ),
                    ],
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

/// Bottom sheet shown when the player taps the pause control.
Future<void> showGamePausedSheet(
  BuildContext context, {
  required VoidCallback onResume,
  required VoidCallback onRestart,
  required VoidCallback onExit,
  required VoidCallback onViewDiagnostics,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
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
          Text('Game Paused', style: AppText.display(size: 22)),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Resume',
            onPressed: () {
              Navigator.pop(context);
              onResume();
            },
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Restart Game',
            onPressed: () {
              Navigator.pop(context);
              onRestart();
            },
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Dev page',
            isDanger: false,
            onPressed: () {
              Navigator.pop(context);
              onViewDiagnostics();
            },
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Exit to Home',
            isDanger: true,
            onPressed: () {
              Navigator.pop(context);
              onExit();
            },
          ),
        ],
      ),
    ),
  );
}
