import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../repositories/poem_repository.dart';
import '../services/settings_service.dart';
import '../theme/design_tokens.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  final PoemRepository repository;
  final SettingsService settingsService;

  const SplashPage({
    super.key,
    required this.repository,
    required this.settingsService,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // upperBound set to 52 / 249 so it only plays the first 52 frames:
    // - Frames 0–27: Active motion (~1.08 seconds at 1x normal speed)
    // - Frames 27–52: Stationary hold (~1.0 second)
    // Total playback time: ~2 seconds at normal speed without skipping frames.
    _controller = AnimationController(
      vsync: this,
      upperBound: 52 / 249,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(
          repository: widget.repository,
          settingsService: widget.settingsService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: Lottie.asset(
            'assets/animations/splash_animation.json',
            controller: _controller,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.color(
                  const ['**'],
                  value: colors.label,
                ),
              ],
            ),
            onLoaded: (composition) {
              _controller
                ..duration = composition.duration * (52 / 249)
                ..forward().whenComplete(_navigateToHome);
            },
          ),
        ),
      ),
    );
  }
}
