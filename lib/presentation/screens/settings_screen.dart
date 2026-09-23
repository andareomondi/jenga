import 'package:flutter/material.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/services/game_settings_service.dart';
import 'package:jenga/presentation/widgets/toast.dart';
import 'package:jenga/presentation/widgets/buttons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GameSettingsService _settings = GameSettingsService();

  late int _maxBlocks;
  late int _minPlayers;
  late int _maxPlayers;
  late int _challengeFrequency;
  late int _minBlocksForGame;
  late double _unstableThreshold;
  late int _blockCollapseDelta;
  late int _baseBlockRemovalPoints;
  late int _easyRewardPoints;
  late int _mediumRewardPoints;
  late int _hardRewardPoints;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _maxBlocks = _settings.getMaxBlocks();
      _minPlayers = _settings.getMinPlayers();
      _maxPlayers = _settings.getMaxPlayers();
      _challengeFrequency = _settings.getChallengeFrequency();
      _minBlocksForGame = _settings.getMinBlocksForGame();
      _unstableThreshold = _settings.getUnstableThreshold();
      _blockCollapseDelta = _settings.getBlockCollapseDelta();
      _baseBlockRemovalPoints = _settings.getBaseBlockRemovalPoints();
      _easyRewardPoints = _settings.getEasyRewardPoints();
      _mediumRewardPoints = _settings.getMediumRewardPoints();
      _hardRewardPoints = _settings.getHardRewardPoints();
      _hasChanges = false;
    });
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _settings.setMaxBlocks(_maxBlocks);
      await _settings.setMinPlayers(_minPlayers);
      await _settings.setMaxPlayers(_maxPlayers);
      await _settings.setChallengeFrequency(_challengeFrequency);
      await _settings.setMinBlocksForGame(_minBlocksForGame);
      await _settings.setUnstableThreshold(_unstableThreshold);
      await _settings.setBlockCollapseDelta(_blockCollapseDelta);
      await _settings.setBaseBlockRemovalPoints(_baseBlockRemovalPoints);
      await _settings.setEasyRewardPoints(_easyRewardPoints);
      await _settings.setMediumRewardPoints(_mediumRewardPoints);
      await _settings.setHardRewardPoints(_hardRewardPoints);

      if (mounted) {
        setState(() => _hasChanges = false);
        ToastUtility.showSuccess(context, message: 'Settings saved ✓');
      }
    } catch (e) {
      if (mounted) {
        ToastUtility.showError(context, message: 'Error: $e');
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text('Reset to Defaults?', style: AppText.display(size: 20)),
        content: Text(
          'This will reset all settings to their default values. This action cannot be undone.',
          style: AppText.body(size: 14),
        ),
        actions: [
          GhostTextButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Reset',
              style: AppText.body(
                size: 14,
                color: AppColors.coral,
                weight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _settings.resetToDefaults();
        if (mounted) {
          _loadSettings();
          ToastUtility.showSuccess(context, message: 'Settings reset ✓');
        }
      } catch (e) {
        if (mounted) {
          ToastUtility.showError(context, message: 'Error: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.walnut),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: AppText.display(size: 22)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'Gameplay Base',
                children: [
                  _buildNumberSelector(
                    label: 'Max Blocks in Tower',
                    description: 'Total pieces making up the physical tower',
                    value: _maxBlocks,
                    min: 10,
                    max: 100,
                    step: 1,
                    onChanged: (val) => setState(() {
                      _maxBlocks = val;
                      _markChanged();
                    }),
                    format: (val) => '$val',
                  ),
                  const _Divider(),
                  _buildNumberSelector(
                    label: 'Challenge Frequency',
                    description: 'How often challenges trigger',
                    value: _challengeFrequency,
                    min: 1,
                    max: 10,
                    step: 1,
                    onChanged: (val) => setState(() {
                      _challengeFrequency = val;
                      _markChanged();
                    }),
                    format: (val) => '1:$val',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Player Limits',
                children: [
                  _buildNumberSelector(
                    label: 'Minimum Players',
                    description: 'Fewest players allowed in a session',
                    value: _minPlayers,
                    min: 1,
                    max: 10,
                    step: 1,
                    onChanged: (val) {
                      setState(() {
                        _minPlayers = val;
                        if (_minPlayers > _maxPlayers)
                          _maxPlayers = _minPlayers;
                        _markChanged();
                      });
                    },
                    format: (val) => '$val',
                  ),
                  const _Divider(),
                  _buildNumberSelector(
                    label: 'Maximum Players',
                    description: 'Most players allowed in a session',
                    value: _maxPlayers,
                    min: 1,
                    max: 10,
                    step: 1,
                    onChanged: (val) {
                      setState(() {
                        _maxPlayers = val;
                        if (_maxPlayers < _minPlayers)
                          _minPlayers = _maxPlayers;
                        _markChanged();
                      });
                    },
                    format: (val) => '$val',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Physics & State',
                children: [
                  _buildNumberSelector(
                    label: 'Min Blocks for Game',
                    description:
                        'Remaining blocks before game-over conditions apply',
                    value: _minBlocksForGame,
                    min: 3,
                    max: 20,
                    step: 1,
                    onChanged: (val) => setState(() {
                      _minBlocksForGame = val;
                      _markChanged();
                    }),
                    format: (val) => '$val',
                  ),
                  const _Divider(),
                  _buildNumberSelector(
                    label: 'Collapse Delta',
                    description:
                        'Blocks removed at once that trigger a collapse state',
                    value: _blockCollapseDelta,
                    min: 1,
                    max: 10,
                    step: 1,
                    onChanged: (val) => setState(() {
                      _blockCollapseDelta = val;
                      _markChanged();
                    }),
                    format: (val) => '$val',
                  ),
                  const _Divider(),
                  _buildSlider(
                    label: 'Unstable Threshold',
                    description:
                        'Tower triggers wobble warning below this percentage',
                    value: _unstableThreshold,
                    min: 0.1,
                    max: 0.5,
                    divisions: 8,
                    onChanged: (val) => setState(() {
                      _unstableThreshold = val;
                      _markChanged();
                    }),
                    format: (val) => '${(val * 100).toInt()}%',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Scoring Rules',
                children: [
                  _buildNumberSelector(
                    label: 'Base Block Points',
                    description: 'Awarded for a successful standard removal',
                    value: _baseBlockRemovalPoints,
                    min: 1,
                    max: 50,
                    step: 1,
                    onChanged: (val) => setState(() {
                      _baseBlockRemovalPoints = val;
                      _markChanged();
                    }),
                    format: (val) => '+$val',
                  ),
                  const _Divider(),
                  _buildNumberSelector(
                    label: 'Easy Challenge',
                    description: 'Bonus points for easy challenges',
                    value: _easyRewardPoints,
                    min: 5,
                    max: 50,
                    step: 5,
                    onChanged: (val) => setState(() {
                      _easyRewardPoints = val;
                      _markChanged();
                    }),
                    format: (val) => '+$val',
                  ),
                  const _Divider(),
                  _buildNumberSelector(
                    label: 'Medium Challenge',
                    description: 'Bonus points for medium challenges',
                    value: _mediumRewardPoints,
                    min: 5,
                    max: 50,
                    step: 5,
                    onChanged: (val) => setState(() {
                      _mediumRewardPoints = val;
                      _markChanged();
                    }),
                    format: (val) => '+$val',
                  ),
                  const _Divider(),
                  _buildNumberSelector(
                    label: 'Hard Challenge',
                    description: 'Bonus points for hard challenges',
                    value: _hardRewardPoints,
                    min: 5,
                    max: 100,
                    step: 5,
                    onChanged: (val) => setState(() {
                      _hardRewardPoints = val;
                      _markChanged();
                    }),
                    format: (val) => '+$val',
                  ),
                ],
              ),
              const SizedBox(height: 36),
              PrimaryButton(
                label: _hasChanges ? 'Save Changes' : 'No Changes',
                backgroundColor: _hasChanges
                    ? AppColors.felt
                    : AppColors.walnut.withOpacity(0.25),
                onPressed: _hasChanges ? _saveSettings : null,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Reset to Defaults',
                isDanger: true,
                onPressed: _resetToDefaults,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: AppText.eyebrow()),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberSelector({
    required String label,
    required String description,
    required int value,
    required int min,
    required int max,
    required int step,
    required ValueChanged<int> onChanged,
    required String Function(int) format,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.body(size: 15, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppText.body(size: 12.5, color: AppColors.walnutSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.creamDim,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  color: value > min
                      ? AppColors.walnut
                      : AppColors.walnutSoft.withOpacity(0.3),
                  onPressed: value > min ? () => onChanged(value - step) : null,
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    format(value),
                    textAlign: TextAlign.center,
                    style: AppText.mono(size: 14, weight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: value < max
                      ? AppColors.walnut
                      : AppColors.walnutSoft.withOpacity(0.3),
                  onPressed: value < max ? () => onChanged(value + step) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) format,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppText.body(size: 15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppText.body(
                        size: 12.5,
                        color: AppColors.walnutSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amberPale,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  format(value),
                  style: AppText.mono(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.amberDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                elevation: 2,
                enabledThumbRadius: 10,
              ),
              activeTrackColor: AppColors.amber,
              inactiveTrackColor: AppColors.creamDim,
              thumbColor: AppColors.amber,
              overlayColor: AppColors.amber.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: AppColors.creamDim);
  }
}
