import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../widgets/buttons.dart';

enum ChallengeResult { pending, success, failed }

/// A single, temporary, focused challenge screen. Never shows scoreboard,
/// Bluetooth status, or history — the challenge is the only thing the
/// player needs to think about.
class ChallengeOverlay extends StatelessWidget {
  const ChallengeOverlay({
    super.key,
    required this.challengeText,
    this.icon = '🙈',
    this.result = ChallengeResult.pending,
    this.onReady,
    this.onContinue,
  });

  final String challengeText;
  final String icon;
  final ChallengeResult result;
  final VoidCallback? onReady;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final overlayColor = switch (result) {
      ChallengeResult.pending => AppColors.walnut.withOpacity(0.55),
      ChallengeResult.success => AppColors.felt.withOpacity(0.5),
      ChallengeResult.failed => AppColors.coral.withOpacity(0.45),
    };

    return Container(
      color: overlayColor,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Container(
          padding: const EdgeInsets.fromLTRB(26, 32, 26, 28),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332E2019),
                blurRadius: 30,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result == ChallengeResult.pending) ...[
                Text('YOUR CHALLENGE', style: AppText.eyebrow()),
                const SizedBox(height: 14),
                Text(icon, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 14),
                Text(
                  challengeText,
                  textAlign: TextAlign.center,
                  style: AppText.display(size: 21, weight: FontWeight.w600),
                ),
                const SizedBox(height: 26),
                PrimaryButton(label: 'Ready', onPressed: onReady),
              ] else if (result == ChallengeResult.success) ...[
                const Text('🎉', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 14),
                Text(
                  'Challenge complete!',
                  style: AppText.display(size: 21, weight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  '+15 points',
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.felt,
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Continue',
                  backgroundColor: AppColors.felt,
                  onPressed: onContinue,
                ),
              ] else ...[
                const Text('😅', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 14),
                Text(
                  'Challenge failed',
                  style: AppText.display(size: 21, weight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'No points this round',
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Continue',
                  backgroundColor: AppColors.coral,
                  onPressed: onContinue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
