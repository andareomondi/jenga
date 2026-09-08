import 'package:flutter/material.dart';
import 'package:jenga/models/player_model.dart';
import 'package:jenga/presentation/screens/game_screen.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/ui/bluetooth_scanner_bottomsheet.dart';
import 'package:jenga/presentation/ui/player_registration_bottom_sheet.dart';
import 'package:jenga/presentation/widgets/buttons.dart';
import 'package:jenga/presentation/widgets/toast.dart';

/// Game setup screen that manages the flow from device selection to player registration
class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  bool _deviceConnected = false;
  List<Player> _selectedPlayers = [];
  bool _isLoading = false;

  /// Step 1: Select device
  Future<void> _selectDevice() async {
    try {
      setState(() => _isLoading = true);

      final device = await showBluetoothScannerBottomSheet(
        context,
        onDeviceSelected: () {
          debugPrint('[Setup] Device selected');
        },
      );

      if (device != null && mounted) {
        setState(() => _deviceConnected = true);
        ToastUtility.showSuccess(context, message: 'Device connected! ✓');

        // Automatically proceed to player registration
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 3500));
          await _registerPlayers();
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtility.showError(
          context,
          message: 'Device connection failed: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Step 2: Register players
  Future<void> _registerPlayers() async {
    try {
      final players = await showPlayerRegistrationBottomSheet(context);

      if (players != null && players.isNotEmpty && mounted) {
        setState(() => _selectedPlayers = players);

        debugPrint('[Setup] ${players.length} players registered');
        debugPrint('[Setup] Players: ${players.map((p) => p.name).join(", ")}');

        ToastUtility.showSuccess(
          context,
          message: '${players.length} players ready! Starting game...',
        );

        // Simulate game start delay
        await Future.delayed(const Duration(milliseconds: 3500));

        if (mounted) {
          // Navigate to game screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GameScreen(players: players)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtility.showError(
          context,
          message: 'Player registration failed: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.walnut),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Setup Game', style: AppText.display(size: 22)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
          child: Column(
            children: [
              // Progress indicator
              _buildProgressCard(),
              const SizedBox(height: 32),

              // Instructions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deviceConnected ? '2. Add Players' : '1. Connect Device',
                      style: AppText.display(size: 26, color: AppColors.walnut),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _deviceConnected
                          ? 'Enter 2-6 player names to start the game.'
                          : 'Connect your Jenga tower to get started.',
                      style: AppText.body(
                        size: 15,
                        color: AppColors.walnutSoft,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Device status or player preview
                    if (!_deviceConnected)
                      _buildDeviceStatus()
                    else
                      _buildPlayerPreview(),
                  ],
                ),
              ),

              // Action buttons
              Column(
                children: [
                  if (!_deviceConnected)
                    PrimaryButton(
                      label: 'Connect Device',
                      onPressed: _isLoading ? null : _selectDevice,
                      isLoading: _isLoading,
                    )
                  else
                    Column(
                      children: [
                        PrimaryButton(
                          label: 'Add Players',
                          onPressed: _registerPlayers,
                        ),
                        const SizedBox(height: 8),
                        SecondaryButton(
                          label: 'Change Device',
                          onPressed: () {
                            setState(() => _deviceConnected = false);
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build progress indicator
  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.walnut.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Step 1
          _buildProgressStep(
            number: '1',
            label: 'Device',
            completed: _deviceConnected,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 2,
              color: _deviceConnected
                  ? AppColors.amber
                  : AppColors.walnut.withOpacity(0.14),
            ),
          ),
          const SizedBox(width: 8),

          // Step 2
          _buildProgressStep(
            number: '2',
            label: 'Players',
            completed: _selectedPlayers.isNotEmpty,
          ),
        ],
      ),
    );
  }

  /// Build individual progress step
  Widget _buildProgressStep({
    required String number,
    required String label,
    required bool completed,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: completed
                ? AppColors.felt
                : AppColors.walnut.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: completed
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : Text(
                  number,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w800,
                    color: AppColors.walnut,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppText.body(
            size: 11,
            weight: FontWeight.w600,
            color: AppColors.walnutSoft,
          ),
        ),
      ],
    );
  }

  /// Build device connection status
  Widget _buildDeviceStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.walnut.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          const Text('📡', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Ready to Connect',
            style: AppText.body(
              size: 16,
              weight: FontWeight.w700,
              color: AppColors.walnut,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Make sure your Jenga tower is powered on\nand nearby',
            style: AppText.body(size: 13, color: AppColors.walnutSoft),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build player preview
  Widget _buildPlayerPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.felt.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.felt.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✓ Device connected',
            style: AppText.body(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.felt,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Now add 2-6 players to start playing.',
            style: AppText.body(size: 14, color: AppColors.walnutSoft),
          ),
        ],
      ),
    );
  }
}
