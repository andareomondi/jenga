import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jenga/bloc/game_cubit.dart';
import 'package:jenga/models/player_model.dart';
import 'package:jenga/models/challenge_model.dart';
import 'package:jenga/presentation/ui/challenge_overlay.dart';
import 'package:jenga/services/challenge_service.dart';
import 'package:jenga/presentation/screens/diagonistic_screen.dart';
import 'package:jenga/presentation/screens/play_screen.dart';
import 'package:jenga/presentation/screens/score_board_screen.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/ui/jenga_bottom_nav.dart';
import 'package:jenga/presentation/screens/game_over_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.players});

  final List<Player> players;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  JengaTab _currentTab = JengaTab.play;

  // Track state transitions to trigger overlays
  int _completedCount = 0;
  String? _activeChallengeId;

  // Local state to drive the overlay UI independently of the cubit
  ChallengeProgress? _overlayChallenge;
  ChallengeResult? _overlayResult;

  // Tracks whether to show the collapse animation or the final scoreboard
  bool _showResults = false;

  void _onTabChanged(JengaTab tab) {
    setState(() => _currentTab = tab);
  }

  void _handlePause(BuildContext context) {
    final cubit = context.read<GameCubit>();
    showGamePausedSheet(
      context,
      onResume: () {},
      onRestart: () {
        setState(() => _showResults = false);
        cubit.restartGame();
      },
      onEndGame: () => cubit.endGame(),
      onExit: () => Navigator.of(context).popUntil((route) => route.isFirst),
      onViewDiagnostics: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DiagnosticsScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameCubit(initialPlayers: widget.players),
      child: BlocConsumer<GameCubit, GameState>(
        listenWhen: (previous, current) {
          return previous.activeChallenge != current.activeChallenge ||
              previous.completedChallenges.length !=
                  current.completedChallenges.length;
        },
        listener: (context, state) {
          // Trigger overlay when a NEW challenge becomes active
          if (state.activeChallenge != null &&
              state.activeChallenge!.challenge.id != _activeChallengeId) {
            _activeChallengeId = state.activeChallenge!.challenge.id;
            setState(() {
              _overlayChallenge = state.activeChallenge;
              _overlayResult = ChallengeResult.pending;
            });
          }

          // Trigger overlay when a challenge completes or fails
          if (state.completedChallenges.length > _completedCount) {
            _completedCount = state.completedChallenges.length;
            final lastCompleted = state.completedChallenges.last;

            setState(() {
              _overlayChallenge = lastCompleted;
              _overlayResult = lastCompleted.status == ChallengeStatus.completed
                  ? ChallengeResult.success
                  : ChallengeResult.failed;
            });
          }
        },
        builder: (context, state) {
          // ------------------------------------------------------------------
          // GAME OVER FLOW INTERCEPT
          // ------------------------------------------------------------------
          if (state.phase == GamePhase.gameOver) {
            if (_showResults) {
              final winner = state.rankedPlayers.isNotEmpty
                  ? state.rankedPlayers.first
                  : null;

              return Scaffold(
                backgroundColor: AppColors.cream,
                body: ResultsScreen(
                  winner: winner?.name ?? 'No one',
                  summary:
                      '${winner?.points ?? 0} points · ${winner?.blocksRemoved ?? 0} blocks removed',
                  ranked: state.rankedPlayers
                      .map((p) => ResultsPlayer(p.name, p.points))
                      .toList(),
                  onPlayAgain: () {
                    setState(() => _showResults = false);
                    context.read<GameCubit>().restartGame();
                  },
                  onBackToHome: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              );
            } else {
              return Scaffold(
                backgroundColor: AppColors.cream,
                body: TowerCollapseScreen(
                  playerWhoCollapsedIt: state.currentPlayer.name,
                  onViewResults: () {
                    setState(() => _showResults = true);
                  },
                  onPlayAgain: () {
                    setState(() => _showResults = false);
                    context.read<GameCubit>().restartGame();
                  },
                ),
              );
            }
          }

          // ------------------------------------------------------------------
          // STANDARD PLAY FLOW
          // ------------------------------------------------------------------
          return Stack(
            children: [
              Scaffold(
                backgroundColor: AppColors.cream,
                body: _currentTab == JengaTab.play
                    ? PlayScreen(
                        currentPlayerName: state.currentPlayer.name,
                        phase: state.phase,
                        intactLayers: state.intactLayers,
                        totalBlockCount: state.totalBlockCount,
                        isUnstable: state.isUnstable,
                        errorMessage: state.errorMessage,
                        activeChallenge: state.activeChallenge,
                        onPause: () => _handlePause(context),
                      )
                    : ScoreboardScreen(players: state.rankedPlayers),
                bottomNavigationBar: JengaBottomNav(
                  current: _currentTab,
                  onChanged: _onTabChanged,
                ),
              ),

              // Inject the Challenge Overlay on top of everything
              if (_overlayChallenge != null && _overlayResult != null)
                ChallengeOverlay(
                  challengeText: _overlayChallenge!.challenge.description,
                  icon: ChallengeService.getChallengeIcon(
                    _overlayChallenge!.challenge.type,
                  ),
                  result: _overlayResult!,
                  onReady: () {
                    setState(() {
                      _overlayChallenge = null;
                      _overlayResult = null;
                    });
                  },
                  onContinue: () {
                    setState(() {
                      _overlayChallenge = null;
                      _overlayResult = null;
                    });
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
