import 'package:flutter/material.dart';
import 'package:jenga/presentation/theme/theme.dart';

enum JengaTab { play, scoreboard }

/// Primary two-tab navigation. Play is always the default/primary destination.
class JengaBottomNav extends StatelessWidget {
  const JengaBottomNav({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final JengaTab current;
  final ValueChanged<JengaTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppColors.cream.withOpacity(0.94),
        border: const Border(top: BorderSide(color: Color(0x142E2019))),
      ),
      child: Row(
        children: [
          _tabItem(context, JengaTab.play, '🎮', 'Play'),
          _tabItem(context, JengaTab.scoreboard, '🏆', 'Scores'),
        ],
      ),
    );
  }

  Widget _tabItem(
    BuildContext context,
    JengaTab tab,
    String emoji,
    String label,
  ) {
    final active = tab == current;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(tab),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.body(
                size: 11,
                weight: FontWeight.w700,
                color: active ? AppColors.amberDeep : AppColors.walnutSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
