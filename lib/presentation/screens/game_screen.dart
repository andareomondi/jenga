import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jenga/bloc/game_cubit.dart';
import 'package:jenga/models/player_model.dart';
import 'package:jenga/models/challenge_model.dart';
import 'package:jenga/presentation/ui/challenge_overlay.dart';
import 'package:jenga/presentation/ui/connection_lost_overlay.dart';
import 'package:jenga/presentation/ui/bluetooth_scanner_bottomsheet.dart';
import 'package:jenga/services/challenge_service.dart';
import 'package:jenga/presentation/screens/diagonistic_screen.dart';
import 'package:jenga/presentation/screens/play_screen.dart';
import 'package:jenga/presentation/screens/score_board_screen.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/ui/jenga_bottom_nav.dart';
import 'package:jenga/presentation/screens/game_over_screen.dart';
import 'package:jenga/presentation/screens/game_setup_screen.dart';
import 'package:jenga/repo/bluetooth_repository.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.players});

  final List<Player> players;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  JengaTab _currentTab = JengaTab.play;

  int _completedCount = 0;
  String? _activeChallengeId;
  ChallengeProgress? _overlayChallenge;
  ChallengeResult? _overlayResult;
  bool _showResults = false;

  bool _isConnectionLost = false;
  Timer? _connectionPollingTimer;
  final BluetoothRepository _btRepo = BluetoothRepository();

  @override
  void initState() {
    super.initState();
    _startConnectionPolling();
  }

  void _startConnectionPolling() {
    // Poll the Future<bool> isConnected() every 2 seconds
    _connectionPollingTimer = Timer.periodic(const Duration(seconds: 2), (
      _,
    ) async {
      final isCurrentlyConnected = await _btRepo.isConnected();

      if (mounted && _isConnectionLost == isCurrentlyConnected) {
        setState(() {
          _isConnectionLost = !isCurrentlyConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectionPollingTimer?.cancel();
    super.dispose();
  }

  void _onTabChanged(JengaTab tab) {
    setState(() => _currentTab = tab);
  }

  Future<void> _handleReconnect() async {
    final device = await showBluetoothScannerBottomSheet(
      context,
      onDeviceSelected: () {
        debugPrint('[GameScreen] Reconnection intent');
      },
    );

    if (device != null && mounted) {
      // Connect and save the device using your repo method
      await _btRepo.connectAndSaveDevice(device);

      final isNowConnected = await _btRepo.isConnected();
      setState(() {
        _isConnectionLost = !isNowConnected;
      });
    }
  }

  void _handlePause(BuildContext context) {
    final cubit = context.read<GameCubit>();
    // Assuming showGamePausedSheet exists in your codebase
    showGamePausedSheet(
      context,
      onResume: () {},
      onRestart: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const GameSetupScreen()),
          (route) => route.isFirst,
        );
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
      create: (_) =>
          GameCubit(initialPlayers: widget.players, btRepository: _btRepo),
      child: BlocConsumer<GameCubit, GameState>(
        listenWhen: (previous, current) {
          return previous.activeChallenge != current.activeChallenge ||
              previous.completedChallenges.length !=
                  current.completedChallenges.length;
        },
        listener: (context, state) {
          if (state.activeChallenge != null &&
              state.activeChallenge!.challenge.id != _activeChallengeId) {
            _activeChallengeId = state.activeChallenge!.challenge.id;
            setState(() {
              _overlayChallenge = state.activeChallenge;
              _overlayResult = ChallengeResult.pending;
            });
          }

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
                      '${winner?.points ?? 0} points · ${winner?.blocksRemoved ?? 0} blocks',
                  ranked: state.rankedPlayers
                      .map((p) => ResultsPlayer(p.name, p.points))
                      .toList(),
                  onPlayAgain: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const GameSetupScreen(),
                      ),
                      (route) => route.isFirst,
                    );
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
                  onViewResults: () => setState(() => _showResults = true),
                  onPlayAgain: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const GameSetupScreen(),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                ),
              );
            }
          }

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

              if (_overlayChallenge != null && _overlayResult != null)
                ChallengeOverlay(
                  challengeText: _overlayChallenge!.challenge.description,
                  icon: ChallengeService.getChallengeIcon(
                    _overlayChallenge!.challenge.type,
                  ),
                  result: _overlayResult!,
                  onReady: () => setState(() {
                    _overlayChallenge = null;
                    _overlayResult = null;
                  }),
                  onContinue: () => setState(() {
                    _overlayChallenge = null;
                    _overlayResult = null;
                  }),
                ),

              // Highest priority overlay
              if (_isConnectionLost)
                ConnectionLostOverlay(
                  onReconnect: _handleReconnect,
                  onNewGame: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const GameSetupScreen(),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  onExit: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
            ],
          );
        },
      ),
    );
  }
}
