import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/download_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/expressive_loading.dart';
import 'media_bottom_sheet.dart';

class ShareHandlerScreen extends ConsumerStatefulWidget {
  const ShareHandlerScreen({super.key});

  @override
  ConsumerState<ShareHandlerScreen> createState() => _ShareHandlerScreenState();
}

class _ShareHandlerScreenState extends ConsumerState<ShareHandlerScreen> {
  static const _shareChannel = EventChannel('com.zenzer0s.kite/share');
  bool _isGhosting = false;

  @override
  void initState() {
    super.initState();
    _handleIncomingIntent();
  }

  void _handleIncomingIntent() {
    _shareChannel.receiveBroadcastStream().listen((url) async {
      if (url is String && url.isNotEmpty) {
        // Un-ghost instantly because this might be a reused ShareActivity context
        if (mounted) setState(() => _isGhosting = false);
        const platform = MethodChannel('com.zenzer0s.kite/downloader');
        platform.invokeMethod('makeTouchable');

        // Wait for settings to be loaded from disk
        await ref.read(settingsProvider.notifier).waitForLoad();
        final settings = ref.read(settingsProvider);
        final isAuto = settings.defaultFormat == DefaultFormat.auto;

        if (isAuto) {
          final info = await ref.read(downloadProvider.notifier).fetchInfo(url);
          if (info != null) {
            HapticFeedback.mediumImpact();
            ref.read(downloadsProvider.notifier).startDownload(
                  info: info,
                  audioOnly: false,
                );
          }
          _minimizeApp();
        } else {
          if (!mounted) return;
          
          // Trigger fetch in background to populate downloadProvider
          ref.read(downloadProvider.notifier).fetchInfo(url);
          
          // OPEN BOTTOM SHEET INSTANTLY (It will show expressive loading while info is null)
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => MediaBottomSheet(
              isTransparentOverlay: true,
              onDownload: ({required bool audioOnly, String? formatId}) {
                final info = ref.read(downloadProvider).info;
                if (info != null) {
                  ref.read(downloadsProvider.notifier).startDownload(
                        info: info,
                        audioOnly: audioOnly,
                        formatId: formatId,
                      );
                }
                Navigator.pop(ctx);
              },
            ),
          ).whenComplete(() {
            // If user dismissed without downloading, minimize
            _minimizeApp();
          });
        }
      }
    });
  }

  void _minimizeApp() {
    if (!mounted) return;
    setState(() => _isGhosting = true);
    const platform = MethodChannel('com.zenzer0s.kite/downloader');
    platform.invokeMethod('minimize');
  }

  @override
  Widget build(BuildContext context) {
    if (_isGhosting) return const SizedBox.shrink();
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: const Center(
        child: ExpressiveLoadingIndicator(),
      ),
    );
  }
}
