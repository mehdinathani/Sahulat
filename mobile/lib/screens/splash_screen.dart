import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../screens/chat_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _progressController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  
  String _loadingText = 'Initializing services...';
  int _loadingStep = 0;

  final List<String> _loadingSteps = [
    'Initializing core orchestrator...',
    'Establishing secure AI gateway...',
    'Syncing local provider registry...',
    'Sahulat AI is ready!',
  ];

  @override
  void initState() {
    super.initState();
    
    // Logo scale and pulse animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_logoController);
    
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Progress bar animation
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _logoController.forward();
    _progressController.forward();

    // Rotate loading text steps
    _progressController.addListener(() {
      final step = (_progressController.value * _loadingSteps.length).floor();
      if (step != _loadingStep && step < _loadingSteps.length) {
        setState(() {
          _loadingStep = step;
          _loadingText = _loadingSteps[step];
        });
      }
    });

    // Navigate when progress reaches 100%
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ChatScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Correctly watch SettingsProvider so it compiles and is ready
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.themeMode == ThemeMode.dark;
    
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final primaryColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final secondaryColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background subtle ambient gradients (modern glassmorphism design)
          if (isDark)
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.15),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
          if (isDark)
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondaryColor.withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: secondaryColor.withOpacity(0.15),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Branded Glowing Logo Container
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3 * _glowAnimation.value),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 64,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.asset(
                          'assets/icon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if asset not found
                            return Icon(
                              Icons.bolt_rounded,
                              size: 64,
                              color: primaryColor,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Animated Title
                  Text(
                    'Sahulat AI',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 1.5,
                      shadows: isDark
                          ? [
                              Shadow(
                                color: primaryColor.withOpacity(0.5),
                                blurRadius: 10,
                              )
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle tag
                  Text(
                    'Your Intelligent Service Partner',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: subtextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 64),
                  
                  // Custom Gradient Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 6,
                      width: double.infinity,
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Rotating Loading Status Text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _loadingText,
                      key: ValueKey<String>(_loadingText),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: subtextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Footer copyright info
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Powered by Gemini 2.5 Flash',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: subtextColor.withOpacity(0.6),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
