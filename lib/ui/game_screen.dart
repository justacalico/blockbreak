import 'package:flutter/material.dart';

import '../format.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import '../theme.dart';
import 'bag_sheet.dart';
import 'biomes_sheet.dart';
import 'chests_sheet.dart';
import 'dialogs.dart';
import 'gear_sheet.dart';
import 'mine_view.dart';
import 'pickaxes_sheet.dart';
import 'stats_sheet.dart';
import 'widgets.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final report = widget.controller.pendingOfflineReport;
      if (report != null && mounted) {
        showOfflineReport(context, report)
            .then((_) => widget.controller.dismissOfflineReport());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.save();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        widget.controller.onPaused();
      case AppLifecycleState.resumed:
        widget.controller.onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final engine = widget.controller.engine;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _hud(engine),
                Expanded(child: MineView(controller: widget.controller)),
                _navBar(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _hud(GameEngine engine) {
    final state = engine.state;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(engine.biome.name.toUpperCase(),
                    style: BB.displaySm.copyWith(color: BB.dim)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(fmt(state.picks), style: BB.display),
                ),
                Text('${fmt(engine.effectivePps)} picks/sec',
                    style: BB.statDim),
              ],
            ),
          ),
          if (state.runic > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: BB.panel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: BB.runic.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 14, color: BB.runic),
                  const SizedBox(width: 5),
                  Text(fmt(state.runic),
                      style:
                          BB.stat.copyWith(fontSize: 16, color: BB.runic)),
                ],
              ),
            ),
          HudButton(
            icon: Icons.bar_chart,
            tooltip: 'Stats',
            onPressed: () =>
                StatsSheet.show(context, widget.controller),
          ),
        ],
      ),
    );
  }

  Widget _navBar(BuildContext context) {
    final c = widget.controller;
    return Material(
      color: BB.panel,
      child: Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: BB.edge)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.explore,
            label: 'Biomes',
            onTap: () => BiomesSheet.show(context, c),
          ),
          _NavItem(
            icon: Icons.construction,
            label: 'Pickaxes',
            onTap: () => PickaxesSheet.show(context, c),
          ),
          _NavItem(
            icon: Icons.settings,
            label: 'Gear',
            onTap: () => GearSheet.show(context, c),
          ),
          _NavItem(
            icon: Icons.inventory_2,
            label: 'Chests',
            onTap: () => ChestsSheet.show(context, c),
          ),
          _NavItem(
            icon: Icons.backpack,
            label: 'Bag',
            onTap: () => BagSheet.show(context, c),
          ),
        ],
      ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: BB.cream, size: 22),
            const SizedBox(height: 3),
            Text(label,
                style: BB.displaySm.copyWith(
                    fontSize: 7, color: BB.dim)),
          ],
        ),
      ),
    );
  }
}
