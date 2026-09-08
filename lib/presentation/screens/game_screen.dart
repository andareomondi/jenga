import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jenga/bloc/game_cubit.dart';
import 'package:jenga/models/player_model.dart';
import 'package:jenga/presentation/screens/diagonistic_screen.dart';
import 'package:jenga/presentation/screens/play_screen.dart';
import 'package:jenga/presentation/screens/score_board_screen.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/ui/jenga_bottom_nav.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.players});

  final List<Player> players;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  JengaTab _currentTab = JengaTab.play;

  void _onTabChanged(JengaTab tab) {
    setState(() => _currentTab = tab);
  }

  void _handlePause(BuildContext context) {
    final cubit = context.read<GameCubit>();
    showGamePausedSheet(
      context,
      onResume: () {},
      onRestart: () => cubit.restartGame(),
      onExit: () => Navigator.of(context).popUntil((route) => route.isFirst),
      onViewDiagnostics: () {
        final state = cubit.state;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiagnosticsScreen(
              events: state.hardwareEvents,
              blockCount: state.totalBlockCount,
              totalBlocks:
                  state.maxBlockCount, // Dynamic max block ceiling passed here
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameCubit(initialPlayers: widget.players),
      child: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.cream,
            body: _currentTab == JengaTab.play
                ? PlayScreen(
                    currentPlayerName: state.currentPlayer.name,
                    phase: state.phase,
                    intactLayers: state.intactLayers,
                    totalBlockCount:
                        state.totalBlockCount, // Passed dynamic count
                    isUnstable: state.isUnstable,
                    errorMessage: state.errorMessage,
                    onPause: () => _handlePause(context),
                  )
                : ScoreboardScreen(
                    players: state.rankedPlayers,
                    onPlayerTap: (player) {
                      showPlayerStatsSheet(
                        context,
                        name: player.name,
                        stats: const PlayerLifetimeStats(
                          gamesPlayed: 12,
                          gamesWon: 4,
                          blocksRemoved: 34,
                          challenges: 15,
                          bestScore: 120,
                        ),
                      );
                    },
                    onViewHistory: () {},
                  ),
            bottomNavigationBar: JengaBottomNav(
              current: _currentTab,
              onChanged: _onTabChanged,
            ),
          );
        },
      ),
    );
  }
}
