import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/download_provider.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _audioOnly = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    final dl = ref.watch(downloadProvider);

    return Scaffold(
      backgroundColor: zc.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [zc.accent.withValues(alpha: 0.05), zc.bg],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(zc: zc),
                          const SizedBox(height: 32),
                          _UrlInputCard(
                            controller: _urlController,
                            zc: zc,
                            onSubmitted: (url) => _fetchInfo(url),
                          ),
                          const SizedBox(height: 20),
                          _FormatSelector(
                            audioOnly: _audioOnly,
                            onChanged: (v) => setState(() => _audioOnly = v),
                            zc: zc,
                          ),
                          const SizedBox(height: 20),
                          if (dl.info != null &&
                              dl.status != DownloadStatus.fetching)
                            _VideoInfoCard(zc: zc, dl: dl),
                          if (dl.status == DownloadStatus.fetching)
                            _LoadingCard(zc: zc),
                          if (dl.status == DownloadStatus.error)
                            _ErrorCard(
                              zc: zc,
                              message: dl.errorMessage ?? 'Unknown error',
                            ),
                          const Spacer(),
                          _DownloadButton(
                            zc: zc,
                            dl: dl,
                            audioOnly: _audioOnly,
                            onTap: () => _handleDownload(),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _fetchInfo(String url) {
    if (url.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    ref.read(downloadProvider.notifier).fetchInfo(url.trim());
  }

  void _handleDownload() {
    final dl = ref.read(downloadProvider);
    if (dl.status == DownloadStatus.downloading) {
      ref.read(downloadProvider.notifier).cancelDownload();
    } else if (dl.info != null) {
      HapticFeedback.mediumImpact();
      ref.read(downloadProvider.notifier).startDownload(audioOnly: _audioOnly);
    } else {
      _fetchInfo(_urlController.text);
    }
  }
}

class _Header extends StatelessWidget {
  final ZenithColors zc;
  const _Header({required this.zc});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KITE',
          style: GoogleFonts.chakraPetch(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: zc.textPrimary,
            letterSpacing: 4,
          ),
        ),
        Text(
          'paste a link and download',
          style: GoogleFonts.chakraPetch(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            color: zc.textMuted,
          ),
        ),
      ],
    );
  }
}

class _UrlInputCard extends StatelessWidget {
  final TextEditingController controller;
  final ZenithColors zc;
  final ValueChanged<String> onSubmitted;
  const _UrlInputCard({
    required this.controller,
    required this.zc,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: zc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zc.border),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.chakraPetch(fontSize: 14, color: zc.textPrimary),
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.go,
        decoration: InputDecoration(
          hintText: 'https://youtube.com/watch?v=...',
          hintStyle: GoogleFonts.chakraPetch(fontSize: 13, color: zc.textMuted),
          prefixIcon: Icon(Icons.link_rounded, color: zc.textMuted, size: 20),
          suffixIcon: ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: zc.textMuted,
                      size: 18,
                    ),
                    onPressed: () {
                      controller.clear();
                      HapticFeedback.lightImpact();
                    },
                  ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _FormatSelector extends StatelessWidget {
  final bool audioOnly;
  final ValueChanged<bool> onChanged;
  final ZenithColors zc;
  const _FormatSelector({
    required this.audioOnly,
    required this.onChanged,
    required this.zc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(false, Icons.movie_rounded, 'VIDEO'),
        const SizedBox(width: 8),
        _chip(true, Icons.music_note_rounded, 'AUDIO'),
      ],
    );
  }

  Widget _chip(bool isAudio, IconData icon, String label) {
    final isSelected = audioOnly == isAudio;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(isAudio);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? zc.accent.withValues(alpha: 0.15) : zc.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? zc.accent.withValues(alpha: 0.5) : zc.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? zc.accentSoft : zc.textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.chakraPetch(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: isSelected ? zc.accentSoft : zc.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoInfoCard extends StatelessWidget {
  final ZenithColors zc;
  final DownloadState dl;
  const _VideoInfoCard({required this.zc, required this.dl});

  @override
  Widget build(BuildContext context) {
    final info = dl.info!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: zc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (info.thumbnail.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    info.thumbnail,
                    width: 80,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(width: 80, height: 48, color: zc.surfaceAlt),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.chakraPetch(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: zc.textPrimary,
                      ),
                    ),
                    Text(
                      info.uploader,
                      style: GoogleFonts.chakraPetch(
                        fontSize: 11,
                        color: zc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (dl.status == DownloadStatus.downloading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: dl.progress / 100,
                backgroundColor: zc.surfaceAlt,
                valueColor: AlwaysStoppedAnimation(zc.accent),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${dl.progress.toStringAsFixed(1)}%  ${dl.currentLine ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.chakraPetch(fontSize: 10, color: zc.textMuted),
            ),
          ],
          if (dl.status == DownloadStatus.done) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: zc.green, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Download complete',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 11,
                    color: zc.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final ZenithColors zc;
  const _LoadingCard({required this.zc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: zc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zc.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: zc.accent),
          ),
          const SizedBox(width: 14),
          Text(
            'Fetching video info...',
            style: GoogleFonts.chakraPetch(fontSize: 13, color: zc.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final ZenithColors zc;
  final String message;
  const _ErrorCard({required this.zc, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: zc.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zc.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: zc.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.chakraPetch(fontSize: 12, color: zc.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final ZenithColors zc;
  final DownloadState dl;
  final bool audioOnly;
  final VoidCallback onTap;
  const _DownloadButton({
    required this.zc,
    required this.dl,
    required this.audioOnly,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = dl.status == DownloadStatus.downloading;
    final isFetching = dl.status == DownloadStatus.fetching;
    final label = isDownloading
        ? 'CANCEL'
        : dl.info != null
        ? 'DOWNLOAD'
        : 'FETCH INFO';
    final icon = isDownloading
        ? Icons.cancel_outlined
        : dl.info != null
        ? Icons.download_rounded
        : Icons.search_rounded;

    return GestureDetector(
      onTap: (!isFetching) ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isDownloading
              ? LinearGradient(colors: [zc.red.withValues(alpha: 0.7), zc.red])
              : LinearGradient(
                  colors: [zc.accent, zc.accentSoft],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: zc.accent.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isFetching)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              isFetching ? 'FETCHING...' : label,
              style: GoogleFonts.chakraPetch(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
