import 'package:flutter/material.dart';
import 'package:jenga/models/challenge_model.dart';
import 'package:jenga/services/challenge_service.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/ui/player_components.dart';
import 'package:jenga/presentation/widgets/buttons.dart';
import 'package:jenga/presentation/widgets/jenga_tower.dart';
import 'package:jenga/presentation/widgets/toast.dart';

enum GamePhase {
  turn,
  blockRemoved,
  waitingPlacement,
  challengeActive,
  gameOver,
}

class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.currentPlayerName,
    required this.phase,
    required this.intactLayers,
    required this.totalBlockCount,
    this.isUnstable = false,
    this.errorMessage,
    this.activeChallenge,
    this.onPause,
  });

  final String currentPlayerName;
  final GamePhase phase;
  final int intactLayers;
  final int totalBlockCount;
  final bool isUnstable;
  final String? errorMessage;
  final ChallengeProgress? activeChallenge;
  final VoidCallback? onPause;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  @override
  void initState() {
    super.initState();
    _showErrorToastIfNeeded(widget.errorMessage);
  }

  @override
  void didUpdateWidget(covariant PlayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != null &&
        widget.errorMessage != oldWidget.errorMessage) {
      _showErrorToastIfNeeded(widget.errorMessage);
    }
  }

  void _showErrorToastIfNeeded(String? error) {
    if (error == null || error.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ToastUtility.showError(context, message: error);
      }
    });
  }

  int get _blocksRemaining => widget.totalBlockCount;

  String get _instruction {
    // Override standard instructions if a challenge is active
    if (widget.activeChallenge != null &&
        widget.phase != GamePhase.waitingPlacement) {
      return widget.activeChallenge!.challenge.description;
    }

    switch (widget.phase) {
      case GamePhase.turn:
        return 'Remove a block.';
      case GamePhase.blockRemoved:
        return 'Remove a block.';
      case GamePhase.waitingPlacement:
        return 'Place it on top.';
      case GamePhase.challengeActive:
        return '';
      case GamePhase.gameOver:
        return 'Game Over!';
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
                  PlayerAvatar(name: widget.currentPlayerName),
                  RoundIconButton(
                    icon: Icons.pause_rounded,
                    onPressed: widget.onPause,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (widget.phase == GamePhase.blockRemoved &&
                      widget.activeChallenge == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: FeedbackChip(label: 'Block removed', icon: '✓'),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isUnstable) ...[
                        const UnstableBanner(),
                        const SizedBox(height: 14),
                      ],
                      // Show an ongoing Challenge Banner if active
                      if (widget.activeChallenge != null) ...[
                        FeedbackChip(
                          label:
                              'Challenge: ${widget.activeChallenge!.challenge.title}',
                          icon: ChallengeService.getChallengeIcon(
                            widget.activeChallenge!.challenge.type,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        "${widget.currentPlayerName.toUpperCase()}'S TURN",
                        style: AppText.eyebrow(),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _instruction,
                          textAlign: TextAlign.center,
                          style: AppText.body(
                            size: 15,
                            color: widget.activeChallenge != null
                                ? AppColors.felt
                                : AppColors.walnutSoft,
                            weight: widget.activeChallenge != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      JengaTower(
                        fullLayers: widget.intactLayers,
                        wobble: widget.isUnstable,
                        placingTopLayer:
                            widget.phase == GamePhase.waitingPlacement,
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

Future<void> showGamePausedSheet(
  BuildContext context, {
  required VoidCallback onResume,
  required VoidCallback onRestart,
  required VoidCallback onEndGame,
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
            label: 'End Game',
            isDanger: true,
            onPressed: () {
              Navigator.pop(context);
              onEndGame();
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
