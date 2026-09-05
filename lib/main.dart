import 'package:flutter/material.dart';
import 'package:jenga/presentation/screens/home_screen.dart';
import 'package:jenga/presentation/screens/how_to_play_screen.dart';
import 'package:jenga/presentation/theme/theme.dart';
import 'package:jenga/presentation/widgets/toast.dart';

void main() => runApp(const JengaApp());

class JengaApp extends StatelessWidget {
  const JengaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jenga',
      debugShowCheckedModeBanner: false,
      theme: buildJengaTheme(),
      home: const RootShell(),
    );
  }
}

/// Root shell that manages Navigation 1.0 routing.
/// Uses push/pop for screen transitions.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      connectionState: HomeConnectionState.connected,
      onStartGame: () {
        // TODO: Navigate to player setup sheet
        ToastUtility.showDevelopmentWarning(context, message: 'Player setup sheet not implemented yet');
      },
      onOpenSettings: () {
        // Show development warning toast
        ToastUtility.showDevelopmentWarning(context, message: 'Settings not implemented yet');
      },
      onHowToPlay: () {
        // Navigate to How to Play screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
        );
      },
    );
  }
}
