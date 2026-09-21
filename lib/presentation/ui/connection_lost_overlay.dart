import 'package:flutter/material.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/widgets/buttons.dart';
import 'package:jenga/presentation/widgets/toast.dart';

class ConnectionLostOverlay extends StatelessWidget {
  final VoidCallback onReconnect;
  final VoidCallback onNewGame;
  final VoidCallback onExit;

  const ConnectionLostOverlay({
    super.key,
    required this.onReconnect,
    required this.onNewGame,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.walnut.withOpacity(
        0.85,
      ), // Dark overlay blocking interaction
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 26.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bluetooth_disabled,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Connection Lost',
                style: AppText.display(size: 24, color: AppColors.walnut),
              ),
              const SizedBox(height: 8),
              Text(
                'The connection to the Jenga tower dropped. Please reconnect to continue your game.',
                textAlign: TextAlign.center,
                style: AppText.body(size: 15, color: AppColors.walnutSoft),
              ),
              const SizedBox(height: 28),

              PrimaryButton(label: 'Reconnect Device', onPressed: onReconnect),
              const SizedBox(height: 12),

              SecondaryButton(label: 'Start New Game', onPressed: onNewGame),
              const SizedBox(height: 12),

              SecondaryButton(
                label: 'Exit to Home',
                isDanger: true,
                onPressed: onExit,
              ),

              const SizedBox(height: 24),
              Container(height: 1, color: AppColors.walnut.withOpacity(0.1)),
              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: () {
                  ToastUtility.showSuccess(
                    context,
                    message: 'Issue reported and will be worked on.',
                  );
                },
                icon: const Icon(
                  Icons.bug_report,
                  size: 18,
                  color: AppColors.walnutSoft,
                ),
                label: Text(
                  'Report an issue',
                  style: AppText.body(size: 14, color: AppColors.walnutSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
