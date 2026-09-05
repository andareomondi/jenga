import 'package:flutter/material.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/widgets/buttons.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

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
        title: Text('How to Play', style: AppText.display(size: 22)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 24),
          children: [
            _sectionTitle('The Setup'),
            const SizedBox(height: 12),
            _instructionRow(
              '1️⃣',
              'Connect your Jenga tower to the app via Bluetooth',
            ),
            const SizedBox(height: 10),
            _instructionRow('2️⃣', 'Enter player names (2-6 players minimum)'),
            const SizedBox(height: 10),
            _instructionRow('3️⃣', 'Tap "New Game" to begin'),
            const SizedBox(height: 32),
            _sectionTitle('During the Game'),
            const SizedBox(height: 12),
            _instructionRow(
              '🎮',
              'Players take turns removing blocks from the tower',
            ),
            const SizedBox(height: 10),
            _instructionRow(
              '🏗️',
              'Place each removed block on top of the tower',
            ),
            const SizedBox(height: 10),
            _instructionRow('📍', 'Each block removed earns 10 points'),
            const SizedBox(height: 10),
            _instructionRow(
              '✨',
              'Every 3rd turn, you get a challenge for bonus points',
            ),
            const SizedBox(height: 32),
            _sectionTitle('Scoring'),
            const SizedBox(height: 12),
            _scoreRow('Block Removed', '+10 points'),
            const SizedBox(height: 10),
            _scoreRow('Challenge Complete', '+15 points'),
            const SizedBox(height: 10),
            _scoreRow('Tower Collapses', 'Game Over'),
            const SizedBox(height: 32),
            _sectionTitle('Tips'),
            const SizedBox(height: 12),
            _tipRow('Watch the tower carefully for weak spots'),
            const SizedBox(height: 10),
            _tipRow('Remove blocks from the middle layers for stability'),
            const SizedBox(height: 10),
            _tipRow(
              'Use the Scoreboard tab to track player rankings in real-time',
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Back to Home',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppText.display(size: 22, color: AppColors.walnut),
    );
  }

  Widget _instructionRow(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppText.body(size: 15, color: AppColors.walnut),
          ),
        ),
      ],
    );
  }

  Widget _scoreRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.walnut.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppText.body(
              size: 14.5,
              weight: FontWeight.w600,
              color: AppColors.walnut,
            ),
          ),
          Text(
            value,
            style: AppText.mono(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipRow(String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('💡', style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tip,
            style: AppText.body(size: 14.5, color: AppColors.walnutSoft),
          ),
        ),
      ],
    );
  }
}
