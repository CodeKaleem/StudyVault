import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for 3 seconds to show animations
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      if (auth.role == AppRole.teacher) {
        context.go('/teacher');
      } else {
        context.go('/student');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
              Colors.indigo.withOpacity(0.2),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.indigo.withOpacity(0.1),
                border: Border.all(color: Colors.indigo.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 80,
                color: Colors.white,
              ),
            )
            .animate()
            .scale(duration: 800.ms, curve: Curves.easeOutBack)
            .shimmer(delay: 1.seconds, duration: 2.seconds),
            
            const SizedBox(height: 40),
            
            // App Name
            Text(
              'STUDY VAULT',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
            )
            .animate()
            .fadeIn(duration: 800.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
            
            const SizedBox(height: 10),
            
            // Slogan
            Text(
              'EXPAND YOUR EXPERIENCE',
              style: TextStyle(
                color: Colors.indigo.shade300,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                fontSize: 14,
              ),
            )
            .animate(delay: 500.ms)
            .fadeIn(duration: 800.ms)
            .slideY(begin: 0.5, end: 0, curve: Curves.easeOut),
            
            const SizedBox(height: 60),
            
            // About Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'A comprehensive platform for academic excellence, collaboration, and growth.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            )
            .animate(delay: 1200.ms)
            .fadeIn(duration: 1.seconds),
            
            const SizedBox(height: 100),
            
            // Progress Indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade400),
              ),
            )
            .animate(delay: 2.seconds)
            .fadeIn(),
          ],
        ),
      ),
    );
  }
}
