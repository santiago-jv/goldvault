import 'package:flutter/material.dart';
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
    if (state.needsOnboarding) {
      return OnboardingScreen(state: state);
    }
    return GoldVaultShell(state: state);
  }
}

class _StartupSplashScreen extends StatelessWidget {
  const _StartupSplashScreen();

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
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
          ],
        ),
      ),
    );
  }
}
