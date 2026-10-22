import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_and_shells.dart';
import 'state/app_state.dart';
import 'theme/gold_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: GoldVaultState.sbUrl,
    // ignore: deprecated_member_use
    anonKey: GoldVaultState.sbKey,
  );
  final appState = GoldVaultState();
  await appState.init();
  runApp(GoldVaultApp(state: appState));
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
          home: _buildRootGate(),
        );
      },
    );
  }

  Widget _buildRootGate() {
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
