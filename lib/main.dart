import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/server_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.fullUrl,
    anonKey: SupabaseConstants.anonKey,
  );

  runApp(const EduApp());
}

class EduApp extends StatelessWidget {
  const EduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServerProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..init()), // Added with Auto-Init
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return MaterialApp.router(
            title: 'Edu App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF6366F1), // Indigo 500
                secondary: Color(0xFFEC4899), // Pink 500
                surface: Color(0xFF1E293B), // Slate 800
                background: Color(0xFF0F172A),
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              cardTheme: CardThemeData( // Fix: Use CardThemeData
                elevation: 8,
                color: const Color(0xFF1E293B).withOpacity(0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF334155),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
            routerConfig: AppRouter.createRouter(auth),
          );
        },
      ),
    );
  }
}
