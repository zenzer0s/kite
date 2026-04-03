import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/downloads/downloads_screen.dart';
import 'screens/home/share_handler_screen.dart';
import 'widgets/floating_nav_toolbar.dart';

final navigationProvider = NotifierProvider<_NavNotifier, int>(
  _NavNotifier.new,
);

class _NavNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void go(int index) => state = index;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final initialRoute = PlatformDispatcher.instance.defaultRouteName;
  if (initialRoute == '/share_handler') {
    runApp(const ProviderScope(child: ShareApp()));
  } else {
    runApp(const ProviderScope(child: KiteApp()));
  }
}

class ShareApp extends ConsumerWidget {
  const ShareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          color: Colors.transparent,
          theme: AppTheme.lightTheme(lightDynamic).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
          ),
          darkTheme: AppTheme.darkTheme(darkDynamic).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
          ),
          themeMode: themeMode,
          initialRoute: '/share_handler',
          routes: {
            '/share_handler': (context) => const ShareHandlerScreen(),
          },
        );
      },
    );
  }
}

class KiteApp extends ConsumerWidget {
  const KiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Kite',
          theme: AppTheme.lightTheme(lightDynamic),
          darkTheme: AppTheme.darkTheme(darkDynamic),
          themeMode: themeMode,
          home: const MainScaffold(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  late final PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _screens = const [HomeScreen(), DownloadsScreen()];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(navigationProvider, (_, next) {
      if (_currentIndex != next) {
        HapticFeedback.lightImpact();
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

    String currentRoute = '/queue';
    if (_currentIndex == 1) currentRoute = '/downloads';

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            physics: const BouncingScrollPhysics(),
            children: _screens,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavToolbar(
              currentRoute: currentRoute,
              onNavigate: (route) {
                int targetIndex = 0;
                if (route == '/downloads') targetIndex = 1;

                if (_currentIndex != targetIndex) {
                  HapticFeedback.lightImpact();
                  _pageController.animateToPage(
                    targetIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
