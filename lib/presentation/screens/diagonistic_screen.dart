import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jenga/models/tower_event.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/repo/bluetooth_repository.dart';

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

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({
    super.key,
    this.initialEvents = const [],
    this.initialBlockCount = 54,
    this.totalBlocks = 54,
    BluetoothRepository? btRepository,
  }) : btRepository = btRepository;

  final List<DiagEvent> initialEvents;
  final int initialBlockCount;
  final int totalBlocks;
  final BluetoothRepository? btRepository;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  late final BluetoothRepository _btRepository;
  StreamSubscription<TowerEvent>? _eventSubscription;
  final ScrollController _scrollController = ScrollController();

  late List<DiagEvent> _events;
  late int _blockCount;

  @override
  void initState() {
    super.initState();
    _events = List.from(widget.initialEvents);
    _blockCount = widget.initialBlockCount;
    _btRepository = widget.btRepository ?? BluetoothRepository();

    _listenToService();
  }

  void _listenToService() {
    _eventSubscription = _btRepository.towerEventStream.listen(
      _handleTowerEvent,
      onError: (err) {
        _addEvent(
          DiagEvent(
            type: DiagEventType.softTap,
            detail: 'BT Error: $err',
            time: DateTime.now().toIso8601String().substring(11, 19),
          ),
        );
      },
    );
  }

  void _handleTowerEvent(TowerEvent event) {
    if (event.newCount >= 0) {
      _blockCount = event.newCount;
    }

    _addEvent(event.toDiagEvent());
  }

  void _addEvent(DiagEvent diagEvent) {
    setState(() {
      _events.add(diagEvent);
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.walnut),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.walnutSoft,
            ),
            tooltip: 'Clear Logs',
            onPressed: () {
              setState(() {
                _events.clear();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                    'Count: $_blockCount/${widget.totalBlocks}',
                    style: AppText.mono(size: 12, color: AppColors.walnutSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _events.isEmpty
                  ? Center(
                      child: Text(
                        'Listening for hardware events...',
                        style: AppText.mono(
                          size: 12,
                          color: AppColors.walnutSoft,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _events.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0x0F2E2019)),
                      itemBuilder: (context, i) {
                        final e = _events[i];
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
