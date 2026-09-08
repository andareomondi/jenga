import 'package:flutter/material.dart';
import 'package:jenga/presentation/theme/theme.dart';

// Added handPlaced here
enum DiagEventType { added, removed, softTap, handPlaced }

class DiagEvent {
  const DiagEvent({
    required this.type,
    required this.detail,
    required this.time,
  });
  final DiagEventType type;
  final String detail;
  final String time;
}

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({
    super.key,
    required this.events,
    required this.blockCount,
    required this.totalBlocks,
  });

  final List<DiagEvent> events;
  final int blockCount;
  final int totalBlocks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Diagnostics', style: AppText.display(size: 20)),
                  const SizedBox(height: 2),
                  Text(
                    'Developer-only · raw hardware event stream',
                    style: AppText.body(size: 12, color: AppColors.walnutSoft),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Count: $blockCount/$totalBlocks',
                    style: AppText.mono(size: 12, color: AppColors.walnutSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: events.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0x0F2E2019)),
                itemBuilder: (context, i) {
                  final e = events[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _tag(e.type),
                            const SizedBox(width: 8),
                            Text(
                              e.detail,
                              style: AppText.mono(
                                size: 12,
                                color: AppColors.walnut,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          e.time,
                          style: AppText.mono(
                            size: 12,
                            color: AppColors.walnutSoft,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(DiagEventType type) {
    late Color bg;
    late Color fg;
    late String label;
    switch (type) {
      case DiagEventType.added:
        bg = AppColors.feltPale;
        fg = AppColors.felt;
        label = 'ADDED';
        break;
      case DiagEventType.removed:
        bg = AppColors.coralPale;
        fg = AppColors.coral;
        label = 'REMOVED';
        break;
      case DiagEventType.softTap:
        bg = AppColors.amberPale;
        fg = AppColors.amberDeep;
        label = 'SOFT TAP';
        break;
      // Newly added tagging configuration
      case DiagEventType.handPlaced:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        label = 'HAND PLACED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppText.mono(size: 10.5, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}
