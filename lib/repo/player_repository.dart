import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:jenga/models/player_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for managing player data and persistence
class PlayerRepository {
  static final PlayerRepository _instance = PlayerRepository._internal();

  factory PlayerRepository() {
    return _instance;
  }

  PlayerRepository._internal();

  late SharedPreferences _prefs;
  final List<Player> _players = [];

  static const String _playersKey = 'players';
  static const String _lastPlayersKey = 'last_game_players';

  /// Initialize the repository and load saved players
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSavedPlayers();
      debugPrint('[Player-Repo] Repository initialized');
    } catch (e) {
      debugPrint('[Player-Repo] Error initializing: $e');
      rethrow;
    }
  }

  /// Load all saved players from SharedPreferences
  Future<void> _loadSavedPlayers() async {
    try {
      final playerStrings = _prefs.getStringList(_playersKey) ?? [];
      _players.clear();

      for (final playerString in playerStrings) {
        final json = jsonDecode(playerString) as Map<String, dynamic>;
        _players.add(Player.fromJson(json));
      }

      debugPrint('[Player-Repo] Loaded ${_players.length} saved players');
    } catch (e) {
      debugPrint('[Player-Repo] Error loading players: $e');
    }
  }

  /// Get all saved players
  List<Player> getAllPlayers() => _players;

  /// Create a new player
  Future<Player> createPlayer(String name) async {
    try {
      final player = Player(name: name);
      _players.add(player);
      await _savePlayers();
      debugPrint('[Player-Repo] Player created: ${player.name}');
      return player;
    } catch (e) {
      debugPrint('[Player-Repo] Error creating player: $e');
      rethrow;
    }
  }

  /// Update an existing player
  Future<void> updatePlayer(Player player) async {
    try {
      final index = _players.indexWhere((p) => p.id == player.id);
      if (index == -1) {
        throw Exception('Player not found');
      }
      _players[index] = player;
      await _savePlayers();
      debugPrint('[Player-Repo] Player updated: ${player.name}');
    } catch (e) {
      debugPrint('[Player-Repo] Error updating player: $e');
      rethrow;
    }
  }

  /// Delete a player
  Future<void> deletePlayer(String playerId) async {
    try {
      _players.removeWhere((p) => p.id == playerId);
      await _savePlayers();
      debugPrint('[Player-Repo] Player deleted');
    } catch (e) {
      debugPrint('[Player-Repo] Error deleting player: $e');
      rethrow;
    }
  }

  /// Get a player by ID
  Player? getPlayerById(String id) {
    try {
      return _players.firstWhere((p) => p.id == id);
    } catch (e) {
      debugPrint('[Player-Repo] Player not found: $id');
      return null;
    }
  }

  /// Save all players to SharedPreferences
  Future<void> _savePlayers() async {
    try {
      final playerStrings = _players
          .map((p) => jsonEncode(p.toJson()))
          .toList();
      await _prefs.setStringList(_playersKey, playerStrings);
      debugPrint('[Player-Repo] Players saved (${_players.length} total)');
    } catch (e) {
      debugPrint('[Player-Repo] Error saving players: $e');
      rethrow;
    }
  }

  /// Save the current game's players for quick access
  Future<void> saveGamePlayers(List<Player> players) async {
    try {
      final playerStrings = players.map((p) => jsonEncode(p.toJson())).toList();
      await _prefs.setStringList(_lastPlayersKey, playerStrings);
      debugPrint('[Player-Repo] Game players saved (${players.length})');
    } catch (e) {
      debugPrint('[Player-Repo] Error saving game players: $e');
      rethrow;
    }
  }

  /// Load the last game's players
  Future<List<Player>> loadLastGamePlayers() async {
    try {
      final playerStrings = _prefs.getStringList(_lastPlayersKey) ?? [];
      final players = playerStrings
          .map((s) => Player.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
      debugPrint('[Player-Repo] Loaded ${players.length} last game players');
      return players;
    } catch (e) {
      debugPrint('[Player-Repo] Error loading last game players: $e');
      return [];
    }
  }

  /// Clear all players
  Future<void> clearAllPlayers() async {
    try {
      _players.clear();
      await _prefs.remove(_playersKey);
      debugPrint('[Player-Repo] All players cleared');
    } catch (e) {
      debugPrint('[Player-Repo] Error clearing players: $e');
      rethrow;
    }
  }

  /// Get player count
  int getPlayerCount() => _players.length;

  /// Check if player name exists
  bool playerNameExists(String name, {String? excludeId}) {
    return _players.any((p) => p.name == name && p.id != excludeId);
  }
}
