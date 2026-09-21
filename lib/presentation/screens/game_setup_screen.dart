import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jenga/models/player_model.dart';
import 'package:jenga/presentation/screens/game_screen.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/ui/bluetooth_scanner_bottomsheet.dart';
import 'package:jenga/presentation/ui/player_registration_bottom_sheet.dart';
import 'package:jenga/presentation/widgets/buttons.dart';
import 'package:jenga/presentation/widgets/toast.dart';
import 'package:jenga/repo/bluetooth_repository.dart';
import 'package:jenga/repo/player_repository.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  bool _deviceConnected = false;
  List<Player> _selectedPlayers = [];
  bool _blockVerified = false;
  bool _isLoading = false;

  Timer? _connectionMonitorTimer;

  @override
  void initState() {
    super.initState();
    _startConnectionMonitor();
  }

  void _startConnectionMonitor() {
    final btRepo = BluetoothRepository();
    _connectionMonitorTimer = Timer.periodic(const Duration(seconds: 2), (
      _,
    ) async {
      if (!mounted) return;

      try {
        final connected = await btRepo.isConnected();
        if (!connected && _deviceConnected && mounted) {
          setState(() {
            _deviceConnected = false;
            _blockVerified = false;
          });
          ToastUtility.showError(
            context,
            message: 'Connection dropped. Please reconnect your tower.',
          );
        }
      } catch (e) {
        // Silent catch for periodic polling errors
      }
    });
  }

  @override
  void dispose() {
    _connectionMonitorTimer?.cancel();
    super.dispose();
  }

  Future<void> _selectDevice() async {
    try {
      setState(() => _isLoading = true);
      final device = await showBluetoothScannerBottomSheet(
        context,
        onDeviceSelected: () => debugPrint('[Setup] Device selected'),
      );

      if (device != null && mounted) {
        setState(() => _deviceConnected = true);
        ToastUtility.showSuccess(context, message: 'Device connected! ✓');

        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 1000));
          await _registerPlayers();
        }
      }
    } catch (e) {
      if (mounted)
        ToastUtility.showError(context, message: 'Connection failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerPlayers() async {
    try {
      final players = await showPlayerRegistrationBottomSheet(context);

      if (players != null && players.isNotEmpty && mounted) {
        // Save the players to the local PlayerRepository
        await PlayerRepository().saveGamePlayers(players);

        setState(() => _selectedPlayers = players);
        ToastUtility.showSuccess(
          context,
          message: '${players.length} players ready!',
        );

        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 1000));
          await _verifyTower();
        }
      }
    } catch (e) {
      if (mounted)
        ToastUtility.showError(context, message: 'Player registration failed.');
    }
  }

  Future<void> _verifyTower() async {
    setState(() => _isLoading = true);
    final btRepo = BluetoothRepository();

    try {
      // 1. Send the status command via the service pipeline
      await btRepo.sendData("status");

      // 2. Listen for the immediate hardware response via the broadcast stream
      final event = await btRepo.towerEventStream
          .firstWhere((e) => e.newCount >= 0)
          .timeout(const Duration(seconds: 5));

      if (event.newCount == 54) {
        setState(() {
          _blockVerified = true;
          _isLoading = false;
        });

        if (mounted) {
          ToastUtility.showSuccess(
            context,
            message: 'Tower verified: 54 blocks!',
          );
          await Future.delayed(const Duration(milliseconds: 1200));

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => GameScreen(players: _selectedPlayers),
              ),
            );
          }
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ToastUtility.showError(
            context,
            message:
                'Tower has ${event.newCount} blocks. Stack exactly 54 and try again.',
          );
        }
      }
    } on TimeoutException {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastUtility.showError(
          context,
          message: 'Verification timed out. Is the tower turned on?',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastUtility.showError(context, message: 'Verification failed: $e');
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
          child: Column(
            children: [
              _buildProgressCard(),
              const SizedBox(height: 32),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStepTitle(),
                      style: AppText.display(size: 26, color: AppColors.walnut),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getStepSubtitle(),
                      style: AppText.body(
                        size: 15,
                        color: AppColors.walnutSoft,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (!_deviceConnected)
                      _buildDeviceStatus()
                    else if (_selectedPlayers.isEmpty)
                      _buildPlayerPreview()
                    else
                      _buildVerifyStatus(),
                  ],
                ),
              ),

              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    if (!_deviceConnected) return '1. Connect Device';
    if (_selectedPlayers.isEmpty) return '2. Add Players';
    return '3. Verify Tower';
  }

  String _getStepSubtitle() {
    if (!_deviceConnected) return 'Connect your Jenga tower to get started.';
    if (_selectedPlayers.isEmpty)
      return 'Enter 2-6 player names to start the game.';
    return 'Checking if the tower is fully built with exactly 54 blocks.';
  }

  Widget _buildActionButtons() {
    if (!_deviceConnected) {
      return PrimaryButton(
        label: 'Connect Device',
        onPressed: _isLoading ? null : _selectDevice,
        isLoading: _isLoading,
      );
    } else if (_selectedPlayers.isEmpty) {
      return Column(
        children: [
          PrimaryButton(label: 'Add Players', onPressed: _registerPlayers),
          const SizedBox(height: 8),
          SecondaryButton(
            label: 'Change Device',
            onPressed: () => setState(() => _deviceConnected = false),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          PrimaryButton(
            label: 'Verify Block Count',
            onPressed: _isLoading ? null : _verifyTower,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: 'Change Players',
            onPressed: () => setState(() => _selectedPlayers = []),
          ),
        ],
      );
    }
  }

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
          _buildProgressStep(
            number: '1',
            label: 'Device',
            completed: _deviceConnected,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 2,
              color: _deviceConnected
                  ? AppColors.amber
                  : AppColors.walnut.withOpacity(0.14),
            ),
          ),
          const SizedBox(width: 4),
          _buildProgressStep(
            number: '2',
            label: 'Players',
            completed: _selectedPlayers.isNotEmpty,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 2,
              color: _selectedPlayers.isNotEmpty
                  ? AppColors.amber
                  : AppColors.walnut.withOpacity(0.14),
            ),
          ),
          const SizedBox(width: 4),
          _buildProgressStep(
            number: '3',
            label: 'Verify',
            completed: _blockVerified,
          ),
        ],
      ),
    );
  }

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

  Widget _buildPlayerPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.felt.withOpacity(0.3)),
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

  Widget _buildVerifyStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.felt.withOpacity(0.3)),
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
          const SizedBox(height: 8),
          Text(
            '✓ ${_selectedPlayers.length} Players added',
            style: AppText.body(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.felt,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap verify below to scan the tower structure.',
            style: AppText.body(size: 14, color: AppColors.walnutSoft),
          ),
        ],
      ),
    );
  }
}
