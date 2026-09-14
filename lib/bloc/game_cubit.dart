import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jenga/models/player_model.dart';
import 'package:jenga/models/tower_event.dart';
import 'package:jenga/presentation/screens/diagonistic_screen.dart';
import 'package:jenga/presentation/screens/play_screen.dart';
import 'package:jenga/presentation/screens/score_board_screen.dart';
import 'package:jenga/repo/bluetooth_repository.dart';
import 'package:jenga/services/challenge_service.dart';
import 'package:jenga/models/challenge_model.dart';
import 'package:flutter/material.dart';

class GameState {
  final List<Player> players;
  final int currentPlayerIndex;
  final GamePhase phase;
  final int totalBlockCount;
  final int maxBlockCount;
  final int intactLayers;
  final bool isUnstable;
  final Map<String, ScoreboardPlayer> playerStats;
  final List<DiagEvent> hardwareEvents;
  final String? errorMessage;
  final DateTime? errorTimestamp;
  final ChallengeProgress? activeChallenge;
  final List<ChallengeProgress> completedChallenges;
  final int turnCount;

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
    this.activeChallenge,
    this.completedChallenges = const [],
    this.turnCount = 0,
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
    bool clearError = false, // Added to allow clearing errors
    DateTime? errorTimestamp,
    ChallengeProgress? activeChallenge,
    bool clearActiveChallenge =
        false, // Added to allow clearing the active challenge
    List<ChallengeProgress>? completedChallenges,
    int? turnCount,
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
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorTimestamp: clearError
          ? null
          : (errorTimestamp ?? this.errorTimestamp),
      activeChallenge: clearActiveChallenge
          ? null
          : (activeChallenge ?? this.activeChallenge),
      completedChallenges: completedChallenges ?? this.completedChallenges,
      turnCount: turnCount ?? this.turnCount,
    );
  }
}

class GameCubit extends Cubit<GameState> {
  final BluetoothRepository _btRepository;
  final ChallengeService _challengeService = ChallengeService();
  StreamSubscription<TowerEvent>? _eventSubscription;
  Timer? _challengeTimer;

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
           maxBlockCount: 54,
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
           completedChallenges: const [],
           turnCount: 0,
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

  /// Calculate points for a block removal based on tower state
  int _calculateBlockRemovalPoints({
    required int totalBlockCount,
    required int intactLayers,
    required bool isUnstable,
  }) {
    if (isUnstable) {
      return 15;
    }
    if (totalBlockCount <= 10) {
      return 12;
    }
    if (intactLayers >= 12) {
      return 8;
    }
    return 10;
  }

  void _handleTowerEvent(TowerEvent event) {
    final updatedTotalCount = event.newCount >= 0
        ? event.newCount
        : state.totalBlockCount;

    final updatedMaxCount = updatedTotalCount > state.maxBlockCount
        ? updatedTotalCount
        : state.maxBlockCount;

    final updatedLayers = (updatedTotalCount / 3).floor().clamp(0, 18);
    final updatedEvents = [event.toDiagEvent(), ...state.hardwareEvents];

    final isUnstableNow = updatedTotalCount < (state.maxBlockCount * 0.2);

    var nextState = state.copyWith(
      totalBlockCount: updatedTotalCount,
      maxBlockCount: updatedMaxCount,
      intactLayers: updatedLayers,
      hardwareEvents: updatedEvents,
      isUnstable: isUnstableNow,
    );

    if (event.type == TowerEventType.removed) {
      if (state.phase == GamePhase.turn ||
          state.phase == GamePhase.blockRemoved) {
        final currentStats = state.playerStats[state.currentPlayer.id];
        final updatedStats = Map<String, ScoreboardPlayer>.from(
          state.playerStats,
        );

        int pointsEarned = _calculateBlockRemovalPoints(
          totalBlockCount: updatedTotalCount,
          intactLayers: updatedLayers,
          isUnstable: isUnstableNow,
        );

        debugPrint(
          '[Points] Block removal: $pointsEarned (tower: $updatedTotalCount blocks)',
        );

        bool challengeJustCompleted = false;
        ChallengeProgress? updatedChallenge = state.activeChallenge;
        List<ChallengeProgress> updatedCompletedChallenges = List.from(
          state.completedChallenges,
        );

        // Process challenge logic locally before issuing a single emit
        if (state.activeChallenge != null) {
          if (_challengeService.validateChallengeProgress(
            state.activeChallenge!,
            event,
          )) {
            updatedChallenge = state.activeChallenge!.copyWith(
              blocksRemoved: state.activeChallenge!.blocksRemoved + 1,
            );

            debugPrint(
              '[Challenge] Progress: ${updatedChallenge.blocksRemoved}/${updatedChallenge.blocksRequired}',
            );

            if (_challengeService.isChallengeCompleted(updatedChallenge)) {
              challengeJustCompleted = true;

              final reward = _challengeService.calculateReward(
                state.activeChallenge!.challenge,
                onFirstAttempt: true,
                timeRemainingSeconds: updatedChallenge.timeRemainingSeconds,
              );

              pointsEarned += reward;
              debugPrint(
                '[Challenge] Completed! Reward: $reward, Total points: $pointsEarned',
              );

              // Finalize challenge state
              updatedChallenge = updatedChallenge.copyWith(
                status: ChallengeStatus.completed,
              );
              updatedCompletedChallenges.add(updatedChallenge);

              // Cleanup
              _challengeTimer?.cancel();
              _onChallengeCompleted(state.activeChallenge!.challenge, reward);
            }
          }
        }

        // Update player stats
        if (currentStats != null) {
          updatedStats[state.currentPlayer.id] = ScoreboardPlayer(
            name: currentStats.name,
            points: currentStats.points + pointsEarned,
            blocksRemoved: currentStats.blocksRemoved + 1,
            challenges:
                currentStats.challenges + (challengeJustCompleted ? 1 : 0),
          );
        }

        // Single, consolidated emit mapping out exact properties
        emit(
          nextState.copyWith(
            phase: GamePhase.waitingPlacement,
            playerStats: updatedStats,
            activeChallenge: challengeJustCompleted
                ? null
                : updatedChallenge, // Either step forward or nullify
            clearActiveChallenge: challengeJustCompleted, // Force UI clearing
            completedChallenges: updatedCompletedChallenges,
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
        final newTurnCount = state.turnCount + 1;

        var newState = nextState.copyWith(
          phase: GamePhase.turn,
          currentPlayerIndex: nextPlayerIndex,
          turnCount: newTurnCount,
          clearError: true, // Clean up errors for new turn
        );

        if (_shouldTriggerChallenge(newState, newTurnCount)) {
          _triggerNewChallenge(newState);
        } else {
          emit(newState);
        }
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

  bool _shouldTriggerChallenge(GameState state, int turnCount) {
    if (!_challengeService.shouldTriggerChallenge(turnCount)) return false;
    if (state.activeChallenge != null) {
      debugPrint('[Challenge] Skipping—challenge already active');
      return false;
    }
    if (state.totalBlockCount < 6 || state.intactLayers < 2) {
      debugPrint(
        '[Challenge] Skipping—tower too unstable ($state.totalBlockCount blocks, $state.intactLayers layers)',
      );
      return false;
    }
    return true;
  }

  void _triggerNewChallenge(GameState currentState) {
    final challenge = _challengeService.generateRandomChallenge(
      currentTowerBlockCount: currentState.totalBlockCount,
    );

    final blocksRequired = challenge.constraints['blockCount'] as int? ?? 1;

    final progress = ChallengeProgress(
      challenge: challenge,
      status: ChallengeStatus.active,
      blocksRemoved: 0,
      blocksRequired: blocksRequired,
      startTime: DateTime.now(),
      timeRemainingSeconds: challenge.timeLimit,
    );

    debugPrint(
      '[Challenge] Triggered: ${challenge.title} (${challenge.difficulty})',
    );

    if (challenge.timeLimit > 0) {
      _startChallengeTimer(progress);
    }

    emit(currentState.copyWith(activeChallenge: progress));
    _onChallengeTriggered(challenge);
  }

  void _startChallengeTimer(ChallengeProgress progress) {
    _challengeTimer?.cancel();
    int secondsRemaining = progress.challenge.timeLimit;

    _challengeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsRemaining--;

      if (secondsRemaining <= 0) {
        timer.cancel();
        _failChallenge();
      } else {
        emit(
          state.copyWith(
            activeChallenge: state.activeChallenge?.copyWith(
              timeRemainingSeconds: secondsRemaining,
            ),
          ),
        );
      }
    });
  }

  void _failChallenge() {
    if (state.activeChallenge == null) return;

    final failed = state.activeChallenge!.copyWith(
      status: ChallengeStatus.failed,
      completedTime: DateTime.now(),
    );

    _challengeTimer?.cancel();
    _onChallengeFailed(state.activeChallenge!.challenge);

    emit(
      state.copyWith(
        clearActiveChallenge: true, // Force UI clearing
        completedChallenges: [...state.completedChallenges, failed],
      ),
    );
  }

  void skipChallenge() {
    if (state.activeChallenge == null) return;

    final skipped = state.activeChallenge!.copyWith(
      status: ChallengeStatus.skipped,
      completedTime: DateTime.now(),
    );

    _challengeTimer?.cancel();
    debugPrint(
      '[Challenge] Skipped: ${state.activeChallenge!.challenge.title}',
    );

    emit(
      state.copyWith(
        clearActiveChallenge: true, // Force UI clearing
        completedChallenges: [...state.completedChallenges, skipped],
      ),
    );
  }

  void _addDiagEvent(DiagEvent event) {
    emit(state.copyWith(hardwareEvents: [event, ...state.hardwareEvents]));
  }

  void _onChallengeTriggered(Challenge challenge) {
    debugPrint('[Challenge] TRIGGERED: ${challenge.title}');
    debugPrint('[Challenge] Difficulty: ${challenge.difficulty}');
    debugPrint('[Challenge] Description: ${challenge.description}');
    debugPrint('[Challenge] Reward: ${challenge.rewardPoints} points');
  }

  void _onChallengeCompleted(Challenge challenge, int pointsAwarded) {
    debugPrint('[Challenge] ✓ COMPLETED: ${challenge.title}');
    debugPrint('[Challenge] Points awarded: $pointsAwarded');
  }

  void _onChallengeFailed(Challenge challenge) {
    debugPrint('[Challenge] ✗ FAILED: ${challenge.title}');
  }

  void restartGame() {
    _challengeTimer?.cancel();
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
        completedChallenges: const [],
        turnCount: 0,
      ),
    );
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    _challengeTimer?.cancel();
    return super.close();
  }
}
