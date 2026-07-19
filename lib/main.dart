import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'utils/storage.dart';
import 'widgets/offline_page.dart';

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

enum AppState {
  splash,
  offline,
  home,
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppState _appState = AppState.splash;
  Timer? _splashTimer;
  bool _hasTimerFinished = false;
  bool _hasConnectionChecked = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  void _initializeApp() {
    // Start minimum splash delay timer (storing it so we can cancel it in dispose)
    _splashTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _hasTimerFinished = true;
          _checkTransition();
        });
      }
    });

    // Start connection check concurrently
    _checkConnection().then((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _hasConnectionChecked = true;
          _checkTransition();
        });
      }
    });
  }

  void _checkTransition() {
    if (_hasTimerFinished && _hasConnectionChecked) {
      setState(() {
        _appState = _isConnected ? AppState.home : AppState.offline;
      });
    }
  }

  Future<bool> _checkConnection() async {
    // Return true immediately inside unit test runner context to bypass asynchronous network sockets
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }

    try {
      if (kIsWeb) {
        // Fetch a tiny server file to test active connection on Web
        final response = await http.head(Uri.parse('https://raw.githubusercontent.com/genoinit/genoinit.github.io/refs/heads/main/playlist/genoin.m3u')).timeout(const Duration(seconds: 4));
        return response.statusCode == 200;
      } else {
        // Run standard DNS lookup for mobile/desktop
        final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> _retryConnection() async {
    final bool connected = await _checkConnection();
    if (connected && mounted) {
      setState(() {
        _appState = AppState.home;
      });
    }
    return connected;
  }

  Widget _buildCurrentPage() {
    switch (_appState) {
      case AppState.splash:
        return const SplashScreen(key: ValueKey('splash'));
      case AppState.offline:
        return OfflinePage(
          key: const ValueKey('offline'),
          onRetry: _retryConnection,
        );
      case AppState.home:
        return const HomePage(key: ValueKey('home'));
    }
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
        child: _buildCurrentPage(),
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
                        fontWeight: FontWeight.w900,
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
