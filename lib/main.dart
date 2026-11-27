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
  runApp(
    GoldVaultApp(
      state: appState,
      minSplashDuration: const Duration(milliseconds: 1150),
    ),
  );
  appState.bootstrap();
}

class GoldVaultApp extends StatefulWidget {
  final GoldVaultState state;
  final Duration minSplashDuration;

  const GoldVaultApp({
    super.key,
    required this.state,
    this.minSplashDuration = Duration.zero,
  });

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
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 380),
                switchInCurve: GVMotion.standard,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final scale = Tween<double>(begin: 0.985, end: 1.0).animate(animation);
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
  late final AnimationController _ctrl;
  late final Animation<double> _markReveal;
  late final Animation<double> _badgeScale;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _markReveal = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
    );
    _badgeScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _wordmarkOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.32, 0.85, curve: Curves.easeOutCubic),
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.32, 0.85, curve: Curves.easeOutCubic),
      ),
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
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _badgeScale,
                    child: Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.isDark ? c.card : const Color(0xFF0B0B0E),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: c.isDark ? c.lineStrong : const Color(0x18000000),
                        ),
                      ),
                      child: GoldVaultMark(
                        size: 40,
                        color: const Color(0xFFF5F5F7),
                        progress: _markReveal.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _wordmarkOpacity,
                    child: SlideTransition(
                      position: _wordmarkSlide,
                      child: RichText(
                        text: TextSpan(
                          style: GVTxt.h1(c).copyWith(letterSpacing: -0.6),
                          children: [
                            const TextSpan(text: 'Gold'),
                            TextSpan(
                              text: 'Vault',
                              style: TextStyle(color: c.mut, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(c.mut),
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 14),
                    FadeTransition(
                      opacity: _wordmarkOpacity,
                      child: Text(
                        widget.message!,
                        style: GVTxt.xs(c),
                        textAlign: TextAlign.center,
                      ),
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
