import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jenga/models/player_model.dart';
import 'package:jenga/models/tower_event.dart';
import 'package:jenga/presentation/screens/diagonistic_screen.dart';
import 'package:jenga/presentation/screens/play_screen.dart';
import 'package:jenga/presentation/screens/score_board_screen.dart';
import 'package:jenga/repo/bluetooth_repository.dart';

class GameState {
  final List<Player> players;
  final int currentPlayerIndex;
  final GamePhase phase;
  final int totalBlockCount;
  final int maxBlockCount; // Dynamic peak block ceiling
  final int intactLayers;
  final bool isUnstable;
  final Map<String, ScoreboardPlayer> playerStats;
  final List<DiagEvent> hardwareEvents;
  final String? errorMessage;
  final DateTime? errorTimestamp;

  const GameState({
    required this.players,
    required this.currentPlayerIndex,
    required this.phase,
    required this.totalBlockCount,
    required this.maxBlockCount,
    required this.intactLayers,
    required this.isUnstable,
    required this.playerStats,
    required this.hardwareEvents,
    this.errorMessage,
    this.errorTimestamp,
  });

  Player get currentPlayer => players.isNotEmpty
      ? players[currentPlayerIndex]
      : Player(id: '0', name: 'Player');

  List<ScoreboardPlayer> get rankedPlayers {
    final list = playerStats.values.toList();
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }

  GameState copyWith({
    List<Player>? players,
    int? currentPlayerIndex,
    GamePhase? phase,
    int? totalBlockCount,
    int? maxBlockCount,
    int? intactLayers,
    bool? isUnstable,
    Map<String, ScoreboardPlayer>? playerStats,
    List<DiagEvent>? hardwareEvents,
    String? errorMessage,
    DateTime? errorTimestamp,
  }) {
    return GameState(
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      phase: phase ?? this.phase,
      totalBlockCount: totalBlockCount ?? this.totalBlockCount,
      maxBlockCount: maxBlockCount ?? this.maxBlockCount,
      intactLayers: intactLayers ?? this.intactLayers,
      isUnstable: isUnstable ?? this.isUnstable,
      playerStats: playerStats ?? this.playerStats,
      hardwareEvents: hardwareEvents ?? this.hardwareEvents,
      errorMessage: errorMessage ?? this.errorMessage,
      errorTimestamp: errorTimestamp ?? this.errorTimestamp,
    );
  }
}

class GameCubit extends Cubit<GameState> {
  final BluetoothRepository _btRepository;
  StreamSubscription<TowerEvent>? _eventSubscription;

  GameCubit({
    required List<Player> initialPlayers,
    BluetoothRepository? btRepository,
  }) : _btRepository = btRepository ?? BluetoothRepository(),
       super(
         GameState(
           players: initialPlayers,
           currentPlayerIndex: 0,
           phase: GamePhase.turn,
           totalBlockCount: 54,
           maxBlockCount:
               54, // Default baseline, updates dynamically if higher counts appear
           intactLayers: 18,
           isUnstable: false,
           hardwareEvents: const [],
           playerStats: {
             for (var p in initialPlayers)
               p.id: ScoreboardPlayer(
                 name: p.name,
                 points: 0,
                 blocksRemoved: 0,
                 challenges: 0,
               ),
           },
         ),
       ) {
    _listenToTower();
  }

  void _listenToTower() {
    _eventSubscription = _btRepository.towerEventStream.listen(
      _handleTowerEvent,
      onError: (err) => _addDiagEvent(
        DiagEvent(
          type: DiagEventType.softTap,
          detail: 'BT Error: $err',
          time: DateTime.now().toString(),
        ),
      ),
    );
  }

  void _handleTowerEvent(TowerEvent event) {
    final updatedTotalCount = event.newCount >= 0
        ? event.newCount
        : state.totalBlockCount;

    // Watch for the highest number passed and update max block ceiling if greater
    final updatedMaxCount = updatedTotalCount > state.maxBlockCount
        ? updatedTotalCount
        : state.maxBlockCount;

    final updatedLayers = (updatedTotalCount / 3).floor().clamp(0, 18);
    final updatedEvents = [event.toDiagEvent(), ...state.hardwareEvents];

    var nextState = state.copyWith(
      totalBlockCount: updatedTotalCount,
      maxBlockCount: updatedMaxCount,
      intactLayers: updatedLayers,
      hardwareEvents: updatedEvents,
    );

    if (event.type == TowerEventType.removed) {
      if (state.phase == GamePhase.turn ||
          state.phase == GamePhase.blockRemoved) {
        final currentStats = state.playerStats[state.currentPlayer.id];
        final updatedStats = Map<String, ScoreboardPlayer>.from(
          state.playerStats,
        );

        if (currentStats != null) {
          updatedStats[state.currentPlayer.id] = ScoreboardPlayer(
            name: currentStats.name,
            points: currentStats.points + 10,
            blocksRemoved: currentStats.blocksRemoved + 1,
            challenges: currentStats.challenges,
          );
        }

        emit(
          nextState.copyWith(
            phase: GamePhase.waitingPlacement,
            playerStats: updatedStats,
          ),
        );
      } else if (state.phase == GamePhase.waitingPlacement) {
        emit(
          nextState.copyWith(
            errorMessage:
                "Incorrect move! You need to place a block on top, not remove one.",
            errorTimestamp: DateTime.now(),
          ),
        );
      }
    } else if (event.type == TowerEventType.added ||
        event.type == TowerEventType.handPlaced) {
      if (state.phase == GamePhase.waitingPlacement) {
        final nextPlayerIndex =
            (state.currentPlayerIndex + 1) % state.players.length;
        emit(
          nextState.copyWith(
            phase: GamePhase.turn,
            currentPlayerIndex: nextPlayerIndex,
          ),
        );
      } else if (state.phase == GamePhase.turn ||
          state.phase == GamePhase.blockRemoved) {
        emit(
          nextState.copyWith(
            errorMessage:
                "Incorrect move! You need to remove a block from the tower.",
            errorTimestamp: DateTime.now(),
          ),
        );
      }
    } else {
      emit(nextState);
    }
  }

  void _addDiagEvent(DiagEvent event) {
    emit(state.copyWith(hardwareEvents: [event, ...state.hardwareEvents]));
  }

  void restartGame() {
    emit(
      GameState(
        players: state.players,
        currentPlayerIndex: 0,
        phase: GamePhase.turn,
        totalBlockCount: state.maxBlockCount,
        maxBlockCount: state.maxBlockCount,
        intactLayers: (state.maxBlockCount / 3).floor(),
        isUnstable: false,
        hardwareEvents: state.hardwareEvents,
        playerStats: {
          for (var p in state.players)
            p.id: ScoreboardPlayer(
              name: p.name,
              points: 0,
              blocksRemoved: 0,
              challenges: 0,
            ),
        },
      ),
    );
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    return super.close();
  }
}
