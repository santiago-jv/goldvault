import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_and_shells.dart';
import 'state/app_state.dart';
import 'theme/gold_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = GoldVaultState();
  runApp(GoldVaultApp(state: appState));
  appState.bootstrap();
}

class GoldVaultApp extends StatelessWidget {
  final GoldVaultState state;
  const GoldVaultApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
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
          home: _buildRootGate(context),
        );
      },
    );
  }

  Widget _buildRootGate(BuildContext context) {
    if (!state.initialized) {
      return const _StartupSplashScreen();
    }
    if (!state.isOnline) {
      return OfflineGuardScreen(state: state);
    }
    if (state.session == null) {
      return GoogleLoginScreen(state: state);
    }
    if (state.needsInitialSync) {
      if (state.loadingCloud) {
        return const _StartupSplashScreen(message: 'Sincronizando tu bóveda…');
      }
      if (state.syncError != null) {
        return SyncErrorScreen(state: state);
      }
      return const _StartupSplashScreen(message: 'Cargando tus datos…');
    }
    if (state.needsOnboarding) {
      return OnboardingScreen(state: state);
    }
    return GoldVaultShell(state: state);
  }
}

class _StartupSplashScreen extends StatelessWidget {
  final String? message;
  const _StartupSplashScreen({this.message});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GoldVaultLogo(fontSize: GVTxt.fsH1),
              const SizedBox(height: 20),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(c.acc),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 14),
                Text(message!, style: GVTxt.sm(c), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
