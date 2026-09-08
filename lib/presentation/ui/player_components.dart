import 'package:flutter/material.dart';
import 'package:jenga/presentation/theme/theme.dart';

/// Circular initial avatar used in the game header and player rows.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.name, this.size = 34});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.amberPale,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppText.body(
          size: size * 0.38,
          weight: FontWeight.w800,
          color: AppColors.amberDeep,
        ),
      ),
    );
  }
}

/// A single row on the Scoreboard tab: rank medal, name, light meta line, points.
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.rank,
    required this.name,
    required this.points,
    this.meta,
    this.onTap,
  });

  final int rank; // 1, 2, 3...
  final String name;
  final int points;
  final String? meta;
  final VoidCallback? onTap;

  String get _medal {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  _medal,
                  style: const TextStyle(fontSize: 19),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppText.body(size: 15, weight: FontWeight.w700),
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta!,
                        style: AppText.body(
                          size: 11.5,
                          weight: FontWeight.w500,
                          color: AppColors.walnutSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '$points',
                style: AppText.mono(
                  size: 18,
                  weight: FontWeight.w800,
                  color: AppColors.felt,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Transient toast-style confirmation ("Nice! Block removed") shown at the
/// top of the game screen. Auto-dismisses; never blocks the tower view.
class FeedbackChip extends StatelessWidget {
  const FeedbackChip({
    super.key,
    required this.label,
    this.icon = '✓',
    this.color = AppColors.felt,
  });

  final String label;
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2E2019),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        '$icon  $label',
        style: AppText.body(
          size: 13.5,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Small warning pill shown above the tower when it's getting unstable.
class UnstableBanner extends StatelessWidget {
  const UnstableBanner({super.key, this.label = 'Tower is getting shaky'});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.coralPale,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '⚠  $label',
        style: AppText.body(
          size: 12.5,
          weight: FontWeight.w700,
          color: AppColors.coral,
        ),
      ),
    );
  }
}
