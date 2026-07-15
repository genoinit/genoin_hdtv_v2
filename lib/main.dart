import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import 'utils/storage.dart';

void main() async {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage preferences
  await AppStorage.init();

  // Configure edge-to-edge rendering with translucent/transparent system overlay bars
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GENOIN HDTV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E0E16),
        primaryColor: const Color(0xFF667EEA),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF667EEA),
          background: Color(0xFF0E0E16),
          surface: Color(0xFF0F0F1B),
        ),
        // Match premium visual feel of index.html by omitting heavy click highlights
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.white.withOpacity(0.04),
        fontFamily: 'sans-serif',
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showSplash 
            ? const SplashScreen() 
            : const HomePage(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Force transparent edge-to-edge system bars during splash loading
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Elastic scale up from 0 to 1.15, settling to 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.linear),
      ),
    );

    // Fade in transition
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Continuous breathing pulse
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.linear),
      ),
    );

    // Run scale animation, then repeat the breathing loop
    _animationController.forward().then((_) {
      if (mounted) {
        _animationController.repeat(min: 0.5, max: 1.0, reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070D),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Logo Accent with elastic scale and breathing pulse animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final double currentScale = _animationController.value <= 0.5
                        ? _scaleAnimation.value
                        : _pulseAnimation.value;
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.scale(
                        scale: currentScale,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF667EEA),
                          Color(0xFF5A6FD6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'G',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Brand Title in matching italic style
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'GENOIN',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'HDTV',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF667EEA),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                // Spinner
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Developed by: Saidur Rahman Bhuiyan',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version: 1.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
