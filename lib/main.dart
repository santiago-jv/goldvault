import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_and_shells.dart';
import 'state/app_state.dart';
import 'theme/gold_theme.dart';
import 'widgets/gv_motion.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = GoldVaultState();
  runApp(GoldVaultApp(state: appState, minSplashDuration: const Duration(milliseconds: 1550)));
  appState.bootstrap();
}

class GoldVaultApp extends StatefulWidget {
  final GoldVaultState state;
  final Duration minSplashDuration;

  const GoldVaultApp({super.key, required this.state, this.minSplashDuration = Duration.zero});

  @override
  State<GoldVaultApp> createState() => _GoldVaultAppState();
}

class _GoldVaultAppState extends State<GoldVaultApp> {
  late bool _splashHoldActive = widget.minSplashDuration > Duration.zero;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    if (_splashHoldActive) {
      _splashTimer = Timer(widget.minSplashDuration, () {
        if (mounted) setState(() => _splashHoldActive = false);
      });
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return MaterialApp(
          title: 'GoldVault',
          debugShowCheckedModeBanner: false,
          theme: GoldTheme.build(Brightness.light),
          darkTheme: GoldTheme.build(Brightness.dark),
          themeMode: state.themeMode,
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: isDark
                  ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
                  : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: Builder(
            builder: (ctx) {
              final reduceMotion = MediaQuery.disableAnimationsOf(ctx);
              return AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
                switchInCurve: GVMotion.standard,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final scale = Tween<double>(begin: 0.975, end: 1.0).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: scale, child: child),
                  );
                },
                child: _buildRootGate(ctx),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRootGate(BuildContext context) {
    final state = widget.state;
    if (!state.initialized || _splashHoldActive) {
      return const _StartupSplashScreen(key: ValueKey('splash-init'));
    }
    if (!state.isOnline) {
      return OfflineGuardScreen(key: const ValueKey('offline'), state: state);
    }
    if (state.session == null) {
      return GoogleLoginScreen(key: const ValueKey('login'), state: state);
    }
    if (state.needsInitialSync) {
      if (state.loadingCloud) {
        return const _StartupSplashScreen(
          key: ValueKey('splash-sync'),
          message: 'Sincronizando tu bóveda…',
        );
      }
      if (state.syncError != null) {
        return SyncErrorScreen(key: const ValueKey('sync-error'), state: state);
      }
      return const _StartupSplashScreen(
        key: ValueKey('splash-load'),
        message: 'Cargando tus datos…',
      );
    }
    if (state.needsOnboarding) {
      return OnboardingScreen(key: const ValueKey('onboarding'), state: state);
    }
    return GoldVaultShell(key: const ValueKey('shell'), state: state);
  }
}

class _StartupSplashScreen extends StatefulWidget {
  final String? message;
  const _StartupSplashScreen({super.key, this.message});

  @override
  State<_StartupSplashScreen> createState() => _StartupSplashScreenState();
}

class _StartupSplashScreenState extends State<_StartupSplashScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _wordmarkLetters = ['G', 'o', 'l', 'd', 'V', 'a', 'u', 'l', 't'];

  late final AnimationController _ctrl;
  late final Animation<double> _markReveal;
  late final Animation<double> _sheenSweep;
  late final Animation<double> _badgeScale;
  late final Animation<double> _rippleProgress;
  late final Animation<double> _footerOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1350));
    _markReveal = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.62, curve: Curves.easeOutCubic),
    );
    _sheenSweep = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.54, 0.92, curve: Curves.easeInOutCubic),
    );
    _badgeScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.52, curve: Curves.easeOutBack),
      ),
    );
    _rippleProgress = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.18, 0.95, curve: Curves.easeOutCubic),
    );
    _footerOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.62, 1.0, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _ctrl.value < 1.0) {
      _ctrl.value = 1.0;
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final ripple = _rippleProgress.value;
              final rippleAlpha = (1.0 - ripple).clamp(0.0, 1.0) * (c.isDark ? 0.24 : 0.14);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 152,
                    height: 152,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer expanding precision orbital ripple
                        if (ripple > 0.01 && ripple < 0.99)
                          Transform.scale(
                            scale: 0.58 + ripple * 0.46,
                            child: Container(
                              width: 144,
                              height: 144,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: c.txt.withValues(alpha: rippleAlpha),
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                        // Inner soft ambient radial halo
                        Transform.scale(
                          scale: 0.75 + ripple * 0.28,
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  c.txt.withValues(alpha: rippleAlpha * 0.45),
                                  c.txt.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Core squircle badge with wireframe-to-solid folded-V emblem + sheen
                        ScaleTransition(
                          scale: _badgeScale,
                          child: Container(
                            width: 82,
                            height: 82,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.isDark ? c.card : const Color(0xFF0B0B0E),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: c.isDark ? c.lineStrong : const Color(0x1C000000),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: c.isDark ? 0.42 : 0.14),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: GoldVaultMark(
                              size: 44,
                              color: const Color(0xFFF5F5F7),
                              progress: _markReveal.value,
                              sheenProgress: _sheenSweep.value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Staggered letter-by-letter glide reveal for "GoldVault"
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_wordmarkLetters.length, (i) {
                      final start = 0.34 + i * 0.04;
                      final end = (start + 0.28).clamp(0.0, 1.0);
                      final t = Interval(
                        start,
                        end,
                        curve: Curves.easeOutCubic,
                      ).transform(_ctrl.value);
                      final isVaultPart = i >= 4;
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1.0 - t) * 10.0),
                          child: Text(
                            _wordmarkLetters[i],
                            style: GVTxt.h1(c).copyWith(
                              color: isVaultPart ? c.mut : c.txt,
                              fontWeight: isVaultPart ? FontWeight.w500 : FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  FadeTransition(
                    opacity: _footerOpacity,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(c.mut),
                      ),
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 14),
                    FadeTransition(
                      opacity: _footerOpacity,
                      child: Text(widget.message!, style: GVTxt.xs(c), textAlign: TextAlign.center),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
