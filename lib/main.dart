import 'package:eczane_vs/providers/theme_provider.dart';
import 'package:eczane_vs/screens/annoucement_screen.dart';
import 'package:eczane_vs/screens/notification_screen.dart';
import 'package:eczane_vs/screens/password_update_screen.dart';
import 'package:eczane_vs/screens/pharmacy_list_screen.dart';
import 'package:eczane_vs/screens/email_verification_screen.dart';
import 'package:eczane_vs/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:eczane_vs/providers/location_provider.dart';
import 'package:eczane_vs/screens/home_screen.dart';
import 'package:eczane_vs/screens/location_update_screen.dart';
import 'package:eczane_vs/screens/login_screen.dart';
import 'package:eczane_vs/screens/register_screen.dart';
import 'package:eczane_vs/screens/profile_screen.dart';
import 'package:eczane_vs/screens/admin_screen.dart';
import 'package:eczane_vs/services/location_service.dart';
import 'package:eczane_vs/firebase_options.dart';
import 'package:eczane_vs/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.init(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => HomePage(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/verify-email': (context) => const EmailVerificationScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/location': (context) => const LocationUpdateScreen(),
        '/password-update': (context) => const PasswordUpdateScreen(),
        '/announcements': (context) => AnnouncementsScreen(),
        '/notifications': (context) => NotificationScreen(),
        '/pharmacy-list': (context) => const PharmacyListScreen(),
        '/admin': (context) => const AdminScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final LocationService locationService = LocationService();
  String? _errorMessage;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocationAndNavigate();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationAndNavigate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First ensure location services are enabled
      final locationEnabled = await LocationService.ensureLocationEnabled(context);
      if (!locationEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Konum servisleri kapalı. Lütfen konum servislerini açın.';
        });
        return;
      }

      // Get location data
      final location = await LocationService.getCityAndDistrict();
      if (location == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Konum bilgisi alınamadı. Lütfen konum servislerinin açık olduğundan emin olun.';
        });
        return;
      }

      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.setLocation(location);

      User? user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      // Delay for smooth animation
      await Future.delayed(const Duration(milliseconds: 500));

      if (user != null) {
        if (!user.emailVerified) {
          Navigator.of(context).pushReplacementNamed('/verify-email');
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.primary.withOpacity(0.1), theme.colorScheme.surface],
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        Image.asset('assets/images/eczane-seeklogo.png', width: size.width * 0.4),
                        const SizedBox(height: 24),
                        if (_isLoading) ...[
                          SizedBox(
                            width: 45,
                            height: 45,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Konum alınıyor...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 32),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          'Konum alınırken bir hata oluştu',
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error.withOpacity(0.7)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _loadLocationAndNavigate();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Eczane Yönetim Sistemi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
