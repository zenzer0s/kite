import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/download_provider.dart';
import '../../services/download_service.dart';
import '../../theme/app_theme.dart';

class MediaBottomSheet extends ConsumerWidget {
  final void Function({required bool audioOnly, String? formatId}) onDownload;

  const MediaBottomSheet({super.key, required this.onDownload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = ref.watch(downloadProvider);
    final isLoading = dl.status == DownloadStatus.fetching || dl.info == null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 16),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Content Box
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: isLoading
                  ? const _ContainedLoadingIndicator()
                  : _DataState(info: dl.info!, onDownload: onDownload),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContainedLoadingIndicator extends StatelessWidget {
  const _ContainedLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.android) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80.0),
          child: SizedBox(
            width: 100,
            height: 100,
            child: AndroidView(
              viewType: 'com.zenzer0s.kite/expressive_loading',
              creationParamsCodec: const StandardMessageCodec(),
            ),
          ),
        ),
      );
    }

    // Fallback for non-Android
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _DataState extends StatelessWidget {
  final VideoInfo info;
  final void Function({required bool audioOnly, String? formatId}) onDownload;

  const _DataState({required this.info, required this.onDownload});

  static double _effectiveHeight(VideoFormat f) {
    if ((f.height ?? 0) > 0) return f.height!;
    final res = f.resolution ?? '';
    final match = RegExp(r'x(\d+)$').firstMatch(res);
    if (match != null) return double.tryParse(match.group(1)!) ?? 0;
    final hMatch = RegExp(r'^(\d+)p').firstMatch(res);
    if (hMatch != null) return double.tryParse(hMatch.group(1)!) ?? 0;
    return 0;
  }

  List<VideoFormat> _videoFormats() {
    final seen = <double>{};
    final list =
        info.formats
            .where((f) => !f.isAudioOnly && _effectiveHeight(f) > 0)
            .toList()
          ..sort((a, b) => _effectiveHeight(b).compareTo(_effectiveHeight(a)));
    list.retainWhere((f) => seen.add(_effectiveHeight(f)));
    return list;
  }

  List<VideoFormat> _audioFormats() {
    final sorted =
        info.formats.where((f) => f.isAudioOnly && f.containsAudio).toList()
          ..sort((a, b) => (b.abr ?? 0).compareTo(a.abr ?? 0));
    return sorted.isEmpty ? [] : [sorted.first];
  }

  String _qualityLabel(VideoFormat f) {
    final h = _effectiveHeight(f).toInt();
    if (h >= 2160) return '4K Ultra HD';
    if (h >= 1440) return '1440p QHD';
    if (h >= 1080) return '1080p Full HD';
    if (h >= 720) return '720p HD';
    if (h >= 480) return '480p SD';
    if (h >= 360) return '360p';
    if (h > 0) return '${h}p';
    return f.formatNote ?? f.resolution ?? 'Video';
  }

  String _videoSubtitle(VideoFormat f) {
    final parts = <String>[];
    final ext = f.ext?.toUpperCase();
    if (ext != null && ext.isNotEmpty) parts.add(ext);
    if (f.vbr != null && f.vbr! > 0) parts.add('${f.vbr!.toInt()}kbps');
    final size = f.effectiveSize;
    if (size > 0) parts.add(_formatFileSize(size));
    return parts.isNotEmpty ? parts.join(' · ') : (f.formatNote ?? 'Video');
  }

  String _audioSubtitle(VideoFormat f) {
    final parts = <String>[];
    final ext = f.ext?.toUpperCase();
    if (ext != null && ext.isNotEmpty) parts.add(ext);
    if (f.abr != null && f.abr! > 0) parts.add('${f.abr!.toInt()}kbps');
    final size = f.effectiveSize;
    if (size > 0) parts.add(_formatFileSize(size));
    return parts.isNotEmpty ? parts.join(' · ') : (f.formatNote ?? 'Audio');
  }

  @override
  Widget build(BuildContext context) {
    final videoFormats = _videoFormats();
    final audioFormats = _audioFormats();
    final hasRealFormats = videoFormats.isNotEmpty || audioFormats.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormatGroup(
          title: 'MEDIA INFO',
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.network(
                          info.thumbnail,
                          width: 110,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 110,
                                height: 72,
                                color: context.zc.surfaceAlt,
                              ),
                        ),
                        if (info.duration > 0)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatDuration(info.duration),
                                style: GoogleFonts.chakraPetch(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.chakraPetch(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.zc.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          info.uploader,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.chakraPetch(
                            fontSize: 12,
                            color: context.zc.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: Theme.of(context).platform == TargetPlatform.android
              ? AndroidView(
                  viewType: 'com.zenzer0s.kite/quick_actions',
                  creationParams: {'hasThumbnail': info.thumbnail.isNotEmpty},
                  creationParamsCodec: const StandardMessageCodec(),
                  onPlatformViewCreated: (id) {
                    final channel = MethodChannel(
                      'com.zenzer0s.kite/quick_actions_$id',
                    );
                    channel.setMethodCallHandler((call) async {
                      if (call.method == 'onAction') {
                        final action = call.arguments as String;
                        if (action == 'copy') {
                          Clipboard.setData(ClipboardData(text: info.url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'URL copied',
                                style: GoogleFonts.chakraPetch(),
                              ),
                              backgroundColor: context.zc.surfaceAlt,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else if (action == 'open') {
                          launchUrl(
                            Uri.parse(info.url),
                            mode: LaunchMode.externalApplication,
                          );
                        } else if (action == 'thumb') {
                          launchUrl(
                            Uri.parse(info.thumbnail),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    });
                  },
                )
              : SegmentedButton<String>(
                  emptySelectionAllowed: true,
                  selected: const <String>{},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<String> newSelection) {
                    if (newSelection.isEmpty) return;
                    final action = newSelection.first;
                    if (action == 'copy') {
                      Clipboard.setData(ClipboardData(text: info.url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'URL copied',
                            style: GoogleFonts.chakraPetch(),
                          ),
                          backgroundColor: context.zc.surfaceAlt,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else if (action == 'open') {
                      launchUrl(
                        Uri.parse(info.url),
                        mode: LaunchMode.externalApplication,
                      );
                    } else if (action == 'thumb') {
                      launchUrl(
                        Uri.parse(info.thumbnail),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  segments: [
                    ButtonSegment<String>(
                      value: 'copy',
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(
                        'Copy',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ButtonSegment<String>(
                      value: 'open',
                      icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                      label: Text(
                        'Open',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (info.thumbnail.isNotEmpty)
                      ButtonSegment<String>(
                        value: 'thumb',
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: Text(
                          'Thumb',
                          style: GoogleFonts.chakraPetch(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(context.zc.surface),
                    foregroundColor: WidgetStatePropertyAll(
                      context.zc.textPrimary,
                    ),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: context.zc.border),
                    ),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 24),

        if (hasRealFormats) ...[
          if (videoFormats.isNotEmpty) ...[
            _FormatGroup(
              title: 'VIDEO OPTIONS',
              children: videoFormats.take(5).toList().asMap().entries.map((
                entry,
              ) {
                final f = entry.value;
                final isFirst = entry.key == 0;
                return _FormatItem(
                  icon: isFirst
                      ? Icons.videocam_rounded
                      : Icons.videocam_outlined,
                  iconBg: isFirst
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  iconColor: isFirst
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                  title: _qualityLabel(f),
                  subtitle: _videoSubtitle(f),
                  onTap: () =>
                      onDownload(audioOnly: false, formatId: f.formatId),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (audioFormats.isNotEmpty) ...[
            _FormatGroup(
              title: 'AUDIO ONLY',
              children: audioFormats
                  .map(
                    (f) => _FormatItem(
                      icon: Icons.music_note_rounded,
                      iconBg: Theme.of(context).colorScheme.tertiaryContainer,
                      iconColor: Theme.of(context).colorScheme.tertiary,
                      title: f.formatNote ?? 'Best Audio',
                      subtitle: _audioSubtitle(f),
                      onTap: () =>
                          onDownload(audioOnly: true, formatId: f.formatId),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ] else ...[
          _FormatGroup(
            title: 'VIDEO OPTIONS',
            children: [
              _FormatItem(
                icon: Icons.videocam_rounded,
                iconBg: Theme.of(context).colorScheme.primaryContainer,
                iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
                title: 'Best Video + Audio',
                subtitle: 'MP4 • Best available quality',
                onTap: () => onDownload(audioOnly: false),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _FormatGroup(
            title: 'AUDIO ONLY',
            children: [
              _FormatItem(
                icon: Icons.music_note_rounded,
                iconBg: Theme.of(context).colorScheme.tertiaryContainer,
                iconColor: Theme.of(context).colorScheme.tertiary,
                title: 'Best Audio',
                subtitle: 'MP3 Format',
                onTap: () => onDownload(audioOnly: true),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.zc.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.zc.border),
          ),
          child: Row(
            children: [
              Icon(Icons.link_rounded, color: context.zc.textDim, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  info.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 12,
                    color: context.zc.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormatGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormatGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: GoogleFonts.chakraPetch(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
              color: zc.accent,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: zc.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: zc.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: children
                    .asMap()
                    .entries
                    .map(
                      (e) => Column(
                        children: [
                          e.value,
                          if (e.key < children.length - 1)
                            Divider(height: 1, color: zc.border, indent: 52),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormatItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FormatItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.chakraPetch(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: zc.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.chakraPetch(
                      fontSize: 11,
                      color: zc.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.download_rounded, size: 18, color: zc.textDim),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String _formatFileSize(double bytes) {
  if (bytes <= 0) {
    return '';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)}KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
}
