import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/download_provider.dart';
import '../../providers/settings_provider.dart';
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
          final info = await ref.read(downloadProvider.notifier).fetchInfo(url);
          if (info == null) {
             _minimizeApp();
             return;
          }
          
          if (!mounted) return;
          if (!mounted) return;
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withValues(alpha: 0.5),
            builder: (sheetContext) => MediaBottomSheet(
              isTransparentOverlay: true,
              onDownload: ({required bool audioOnly, String? formatId}) {
                // Pop the sheet FIRST so the await completes
                Navigator.of(sheetContext).pop();
                ref.read(downloadsProvider.notifier).startDownload(
                      info: info,
                      audioOnly: audioOnly,
                      formatId: formatId,
                    );
              },
            ),
          );
          _minimizeApp();
        }
      } else {
        _minimizeApp();
      }
    });
  }

  void _minimizeApp() {
    if (mounted) {
      setState(() => _isGhosting = true);
    }
    const platform = MethodChannel('com.zenzer0s.kite/downloader');
    platform.invokeMethod('makeUntouchable');
  }

  @override
  Widget build(BuildContext context) {
    if (_isGhosting) return const SizedBox.shrink();
    
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
