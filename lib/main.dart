import 'package:flutter/material.dart';
import 'models/app_settings.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';
import 'pages/test.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Technician Help',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _RootRouter(),
    );
  }
}

/// Определяет стартовый экран: онбординг или главный экран.
class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.onboardingDone,
      builder: (context, done, _) {
        if (!done) {
          return OnboardingPage(
            onComplete: () {
            },
          );
        }
        return const HomePage();
      },
    );
  }
}