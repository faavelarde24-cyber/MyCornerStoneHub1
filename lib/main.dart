// lib/main.dart
import 'package:cornerstone_hub/services/supabase_service.dart';
import 'package:cornerstone_hub/services/language_service.dart';
import 'package:cornerstone_hub/services/auth_service.dart';
import 'package:cornerstone_hub/providers/book_providers.dart';
import 'package:cornerstone_hub/providers/library_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/auth/login_page.dart';
import 'pages/introduction_animation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  // Load intro preference before running app
  final prefs = await SharedPreferences.getInstance();
  final hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;

  runApp(
    ProviderScope(
      child: MyApp(hasSeenIntro: hasSeenIntro),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final bool hasSeenIntro;

  const MyApp({super.key, required this.hasSeenIntro});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final newUserId = data.session?.user.id;
      
      // Only invalidate if user actually changed (not just token refresh)
      if (_currentUserId != newUserId) {
        debugPrint('🔄 Auth state changed: $_currentUserId → $newUserId');
        _currentUserId = newUserId;
        
        // Invalidate ALL providers when user changes
        ref.invalidate(userBooksProvider);
        ref.invalidate(userLibrariesProvider);
        ref.invalidate(joinedLibrariesProvider);
        ref.invalidate(currentBookIdProvider);
        ref.invalidate(currentPageIndexProvider);
        ref.invalidate(bookPagesProvider);
        
        debugPrint('✅ All providers invalidated for new user');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (context) => AuthService()),
        provider.ChangeNotifierProvider(create: (context) => LanguageService()),
      ],
      child: MaterialApp(
        title: 'Cornerstone Hub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: 'Poppins',
        ),
        home: widget.hasSeenIntro ? const LoginPage() : const IntroWrapper(),
      ),
    );
  }
}

class IntroWrapper extends StatefulWidget {
  const IntroWrapper({super.key});

  @override
  State<IntroWrapper> createState() => _IntroWrapperState();
}

class _IntroWrapperState extends State<IntroWrapper> {
  Future<void> _handleIntroComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenIntro', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionAnimationScreen(
      onComplete: _handleIntroComplete,
    );
  }
}