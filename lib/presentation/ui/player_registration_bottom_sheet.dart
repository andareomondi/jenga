import 'package:flutter/material.dart';
import 'package:jenga/models/player_model.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/widgets/buttons.dart';
import 'package:jenga/repo/player_repository.dart';

/// Opens the player registration bottom sheet
/// Non-dismissable until 2-6 players are registered
Future<List<Player>?> showPlayerRegistrationBottomSheet(BuildContext context) {
  return showModalBottomSheet<List<Player>?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false, // Non-dismissable
    builder: (_) => const PlayerRegistrationBottomSheet(),
  );
}

class PlayerRegistrationBottomSheet extends StatefulWidget {
  const PlayerRegistrationBottomSheet({super.key});

  @override
  State<PlayerRegistrationBottomSheet> createState() =>
      _PlayerRegistrationBottomSheetState();
}

class _PlayerRegistrationBottomSheetState
    extends State<PlayerRegistrationBottomSheet> {
  late PlayerRepository _repository;
  final List<TextEditingController> _controllers = [];
  final List<bool> _isCustomPlayer = [];
  final List<Player> _players = [];
  List<Player> _existingPlayers = [];
  bool _isLoading = true;

  static const int minPlayers = 2;
  static const int maxPlayers = 6;
  static const String addNewSentinel = '__add_new__';

  @override
  void initState() {
    super.initState();
    _repository = PlayerRepository();
    _loadExistingPlayers();
  }

  Future<void> _loadExistingPlayers() async {
    try {
      final existing = await _repository.getAllPlayers();
      if (mounted) {
        setState(() {
          _existingPlayers = existing;
          _isLoading = false;

          // Start with minPlayers slots
          _addPlayerSlot();
          _addPlayerSlot();
        });
      }
    } catch (e) {
      debugPrint('[Registration] Error loading players: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _addPlayerSlot();
          _addPlayerSlot();
        });
      }
    }
  }

  /// Add a new player input slot
  void _addPlayerSlot() {
    if (_controllers.length >= maxPlayers) return;
    setState(() {
      _controllers.add(TextEditingController());
      // Default to dropdown if existing players exist, otherwise text field
      _isCustomPlayer.add(_existingPlayers.isEmpty);
    });
  }

  /// Remove a player input slot
  void _removePlayerSlot(int index) {
    if (_controllers.length <= minPlayers) return;
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      _isCustomPlayer.removeAt(index);
    });
  }

  /// Get validity of player names
  bool get _isValid {
    if (_controllers.length < minPlayers) return false;

    // All players must have non-empty names
    if (!_controllers.every((c) => c.text.trim().isNotEmpty)) return false;

    // No duplicate names
    final names = _controllers.map((c) => c.text.trim().toLowerCase()).toSet();
    if (names.length != _controllers.length) return false;

    return true;
  }

  /// Create players and start game
  Future<void> _startGame() async {
    if (!_isValid) return;

    try {
      _players.clear();

      for (final controller in _controllers) {
        final name = controller.text.trim();
        if (name.isNotEmpty) {
          final player = Player(name: name);
          _players.add(player);
          await _repository.createPlayer(name);
        }
      }

      await _repository.saveGamePlayers(_players);

      if (mounted) {
        Navigator.pop(context, _players);
      }
    } catch (e) {
      debugPrint('[Registration] Error starting game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
      child: _isLoading
          ? const SizedBox(
              height: 250,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.walnut.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Who's playing?",
                    style: AppText.display(size: 22),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle with validation message
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _controllers.length < minPlayers
                        ? 'Add at least $minPlayers players'
                        : _controllers.length > maxPlayers
                        ? 'Max $maxPlayers players'
                        : '${_controllers.length} players',
                    style: AppText.body(
                      size: 14,
                      color: _isValid ? AppColors.walnutSoft : AppColors.coral,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Player input list
                Expanded(
                  child: ListView.builder(
                    itemCount: _controllers.length,
                    itemBuilder: (context, index) {
                      final isCustom = _isCustomPlayer[index];
                      final currentName = _controllers[index].text;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            // Player number badge
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.amberPale,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: AppText.body(
                                  size: 13,
                                  weight: FontWeight.w800,
                                  color: AppColors.amberDeep,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Dropdown or Custom Text Field
                            Expanded(
                              child: (!isCustom && _existingPlayers.isNotEmpty)
                                  ? DropdownButtonFormField<String>(
                                      value:
                                          _existingPlayers.any(
                                            (p) => p.name == currentName,
                                          )
                                          ? currentName
                                          : null,
                                      hint: Text(
                                        'Select player',
                                        style: AppText.body(
                                          size: 15,
                                          color: AppColors.walnutSoft,
                                        ),
                                      ),
                                      onChanged: (val) {
                                        if (val == addNewSentinel) {
                                          setState(() {
                                            _isCustomPlayer[index] = true;
                                            _controllers[index].clear();
                                          });
                                        } else if (val != null) {
                                          setState(() {
                                            _controllers[index].text = val;
                                          });
                                        }
                                      },
                                      items: [
                                        ..._existingPlayers.map(
                                          (p) => DropdownMenuItem<String>(
                                            value: p.name,
                                            child: Text(
                                              p.name,
                                              style: AppText.body(size: 15),
                                            ),
                                          ),
                                        ),
                                        const DropdownMenuItem<String>(
                                          value: addNewSentinel,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.add,
                                                size: 18,
                                                color: AppColors.amberDeep,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                '+ Add new player',
                                                style: TextStyle(
                                                  color: AppColors.amberDeep,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColors.walnut.withOpacity(
                                              0.14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : TextField(
                                      controller: _controllers[index],
                                      onChanged: (_) => setState(() {}),
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: InputDecoration(
                                        hintText: 'New player name',
                                        filled: true,
                                        fillColor: Colors.white,
                                        suffixIcon: _existingPlayers.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.list_alt_rounded,
                                                  size: 20,
                                                  color: AppColors.amberDeep,
                                                ),
                                                tooltip: 'Choose existing',
                                                onPressed: () {
                                                  setState(() {
                                                    _isCustomPlayer[index] =
                                                        false;
                                                    _controllers[index].clear();
                                                  });
                                                },
                                              )
                                            : null,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColors.walnut.withOpacity(
                                              0.14,
                                            ),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.amber,
                                            width: 1.4,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.coral,
                                            width: 1.4,
                                          ),
                                        ),
                                      ),
                                      style: AppText.body(size: 15),
                                    ),
                            ),

                            // Remove button
                            if (_controllers.length > minPlayers)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: IconButton(
                                  onPressed: () => _removePlayerSlot(index),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                    color: AppColors.walnutSoft,
                                  ),
                                  splashRadius: 24,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Add player button
                if (_controllers.length < maxPlayers)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addPlayerSlot,
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                        color: AppColors.amberDeep,
                      ),
                      label: Text(
                        'Add player',
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.amberDeep,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Start game button
                PrimaryButton(
                  label: 'Start Game',
                  onPressed: _isValid ? _startGame : null,
                ),
              ],
            ),
    );
  }
}
