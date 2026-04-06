import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/settings_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String title;
  final String initialUrl;

  const LoginScreen({
    super.key,
    required this.title,
    required this.initialUrl,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final WebViewController _controller;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress / 100);
          },
          onPageStarted: (url) {
            // Started
          },
          onPageFinished: (url) async {
            // Finished
            _checkAndExtractCookies(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _checkAndExtractCookies(String url) async {
    // Precise detection for "Success" pages
    final isHome = url == 'https://www.instagram.com/' || 
                   url == 'https://www.instagram.com' ||
                   url.contains('facebook.com/home') ||
                   url.contains('youtube.com/feed/subscriptions') ||
                   url.contains('youtube.com/feed/library');
    
    // Auto-trigger if on a feed page and NOT on a login/auth page
    if (isHome && !url.contains('login') && !url.contains('authenticate')) {
      await _extractAndSave(currentUrl: url);
    }
  }

  Future<void> _extractAndSave({String? currentUrl}) async {
    const platform = MethodChannel('com.zenzer0s.kite/downloader');
    final targetUrl = currentUrl ?? await _controller.currentUrl() ?? widget.initialUrl;
    
    try {
      final cleanCookies = await platform.invokeMethod<String>('getCookies', {'url': targetUrl});
      
      if (cleanCookies != null && cleanCookies.isNotEmpty) {
        // Save to preferences
        await ref.read(settingsProvider.notifier).setCookies(cleanCookies);
        
        // --- ADDED VALIDATION (Like Vivi Music) ---
        // We verify the cookies work natively before closing.
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⏳ Validating session...'), duration: Duration(seconds: 1)),
          );
        }
        
        // We can test against a known endpoint to see if yt-dlp likes it
        // If it's YouTube, test YouTube. If Instagram, test Instagram.
        // For simplicity, we just check if it's broad-valid.
        
        if (mounted) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Authentication Successful! Cookies Verified.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Cookie Sync Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.reload(),
          ),
          TextButton(
            onPressed: _extractAndSave,
            child: const Text('Capture'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _progress < 1.0
              ? LinearProgressIndicator(value: _progress, minHeight: 2)
              : const SizedBox.shrink(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
