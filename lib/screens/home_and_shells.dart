import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/gv_components.dart';
import '../widgets/gv_motion.dart';
import 'goals_tab.dart';
import 'home_tab.dart';
import 'movement_sheet.dart';
import 'movements_tab.dart';
import 'settings_tab.dart';

export 'account_screens.dart';
export 'movement_sheet.dart';

/// Root navigation shell coordinating the four primary views, frosted glass dock,
/// quick-entry workflow, and sync status banner.
class GoldVaultShell extends StatefulWidget {
  final GoldVaultState state;
  final int initialTab;

  const GoldVaultShell({super.key, required this.state, this.initialTab = 0});

  @override
  State<GoldVaultShell> createState() => _GoldVaultShellState();
}

class _GoldVaultShellState extends State<GoldVaultShell> with WidgetsBindingObserver {
  late int tabIndex = widget.initialTab;
  int _prevTabIndex = 0;
  final TextEditingController _quickCtrl = TextEditingController();
  final TextEditingController _customBankCtrl = TextEditingController();

  void _selectTab(int next) {
    if (next == tabIndex) return;
    setState(() {
      _prevTabIndex = tabIndex;
      tabIndex = next;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _quickCtrl.dispose();
    _customBankCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.state.refreshAndroidPermission();
      widget.state.syncAll();
    }
  }

  void _openMovementSheet({MovementModel? editing, MovementModel? prefilled}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: AnimationStyle(
        duration: GVMotion.medium,
        reverseDuration: const Duration(milliseconds: 210),
        curve: GVMotion.standard,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (_) => MovementSheet(
        state: widget.state,
        editing: editing,
        prefilled: prefilled,
      ),
    );
  }

  void _submitQuickEntry() {
    final raw = _quickCtrl.text.trim();
    if (raw.isEmpty) {
      _openMovementSheet();
      return;
    }
    final pre = widget.state.parseQuickEntry(raw);
    _quickCtrl.clear();
    _openMovementSheet(prefilled: pre);
  }

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final st = widget.state;

    return ListenableBuilder(
      listenable: st,
      builder: (context, _) => Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                children: [
                  if (st.syncError != null || st.hasPendingSync) GVSyncBanner(state: st),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 230),
                      switchInCurve: GVMotion.standard,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final forward = tabIndex >= _prevTabIndex;
                        final beginX = forward ? 0.03 : -0.03;
                        final slide = Tween<Offset>(
                          begin: Offset(beginX, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(tabIndex),
                        child: switch (tabIndex) {
                          0 => HomeTab(
                              state: st,
                              quickController: _quickCtrl,
                              onSubmitQuickEntry: _submitQuickEntry,
                              onOpenSheet: _openMovementSheet,
                              onNavigateMovements: () => _selectTab(1),
                            ),
                          1 => MovementsTab(
                              state: st,
                              onOpenSheet: _openMovementSheet,
                            ),
                          2 => GoalsTab(state: st),
                          _ => SettingsTab(
                              state: st,
                              customBankController: _customBankCtrl,
                              onNavigateHome: () => _selectTab(0),
                            ),
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: GVGlassDock(
          selectedIndex: tabIndex,
          onSelect: _selectTab,
          onAdd: () => _openMovementSheet(),
        ),
      ),
    );
  }
}
