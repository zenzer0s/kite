import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../database/app_database.dart';
import '../../providers/database_provider.dart';
import '../settings/settings_screen.dart';

enum _Filter { all, video, audio }

bool _isAudioExt(String ext) =>
    ext == 'mp3' || ext == 'm4a' || ext == 'opus' || ext == 'aac';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final downloadsAsync = ref.watch(downloadsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.downloadSimple(PhosphorIconsStyle.fill),
                        color: cs.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Downloads',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: cs.onSurface),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    style: IconButton.styleFrom(
                      hoverColor: cs.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: downloadsAsync.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: cs.primary)),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: GoogleFonts.outfit(color: cs.error),
                  ),
                ),
                data: (items) {
                  final filtered = switch (_filter) {
                    _Filter.all => items,
                    _Filter.audio =>
                      items.where((i) => _isAudioExt(i.ext)).toList(),
                    _Filter.video =>
                      items.where((i) => !_isAudioExt(i.ext)).toList(),
                  };
                  if (filtered.isEmpty) {
                    return _EmptyState(cs: cs, filter: _filter);
                  }
                  return _DownloadGrid(items: filtered, cs: cs, ref: ref);
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                children: [
                  Center(
                    child: _FilterBar(
                      current: _filter,
                      onChanged: (f) {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = f);
                      },
                      cs: cs,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _Filter current;
  final ValueChanged<_Filter> onChanged;
  final ColorScheme cs;

  const _FilterBar({
    required this.current,
    required this.onChanged,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          _FilterPill(
            label: 'All',
            icon: Icons.apps_rounded,
            selected: current == _Filter.all,
            onTap: () => onChanged(_Filter.all),
            cs: cs,
          ),
          const SizedBox(width: 1),
          _FilterPill(
            label: 'Video',
            icon: Icons.movie_rounded,
            selected: current == _Filter.video,
            onTap: () => onChanged(_Filter.video),
            cs: cs,
          ),
          const SizedBox(width: 1),
          _FilterPill(
            label: 'Audio',
            icon: Icons.music_note_rounded,
            selected: current == _Filter.audio,
            onTap: () => onChanged(_Filter.audio),
            cs: cs,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.fastOutSlowIn,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: selected ? 24.0 : 0.0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    opacity: selected ? 1.0 : 0.0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 18, color: cs.onPrimary),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.4,
                    color: selected ? cs.onPrimary : cs.onPrimaryContainer,
                  ),
                  child: Text(label, maxLines: 1, overflow: TextOverflow.clip),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadGrid extends StatelessWidget {
  final List<DownloadedItem> items;
  final ColorScheme cs;
  final WidgetRef ref;

  const _DownloadGrid({
    required this.items,
    required this.cs,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) =>
          _DownloadCard(item: items[i], cs: cs, ref: ref),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme cs;
  final _Filter filter;

  const _EmptyState({required this.cs, required this.filter});

  @override
  Widget build(BuildContext context) {
    final label = switch (filter) {
      _Filter.all => 'No downloads yet',
      _Filter.video => 'No videos yet',
      _Filter.audio => 'No audio yet',
    };
    final sub = switch (filter) {
      _Filter.all => 'Your downloaded media will appear here',
      _Filter.video => 'Downloaded videos will appear here',
      _Filter.audio => 'Downloaded audio will appear here',
    };
    final icon = switch (filter) {
      _Filter.all => PhosphorIcons.downloadSimple(PhosphorIconsStyle.regular),
      _Filter.video => PhosphorIcons.filmSlate(PhosphorIconsStyle.regular),
      _Filter.audio => PhosphorIcons.musicNote(PhosphorIconsStyle.regular),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(icon, size: 48, color: cs.outline),
          ),
          const SizedBox(height: 24),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(sub, style: GoogleFonts.outfit(fontSize: 14, color: cs.outline)),
        ],
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final DownloadedItem item;
  final ColorScheme cs;
  final WidgetRef ref;

  const _DownloadCard({
    required this.item,
    required this.cs,
    required this.ref,
  });

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final duration = _formatDuration(item.duration);
    final isAudio = _isAudioExt(item.ext);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        ref.read(databaseProvider).deleteDownload(item.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: cs.onErrorContainer,
          size: 24,
        ),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: item.thumbnail.isNotEmpty
                      ? Image.network(
                          item.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _ThumbnailPlaceholder(isAudio: isAudio, cs: cs),
                        )
                      : _ThumbnailPlaceholder(isAudio: isAudio, cs: cs),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                          height: 1.3,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _ExtBadge(label: item.ext.toUpperCase(), cs: cs),
                          const SizedBox(width: 6),
                          if (duration.isNotEmpty)
                            Text(
                              duration,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: cs.outline,
                              ),
                            ),
                        ],
                      ),
                      if (item.uploader.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.uploader,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: cs.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  final bool isAudio;
  final ColorScheme cs;

  const _ThumbnailPlaceholder({required this.isAudio, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.primaryContainer.withValues(alpha: 0.4),
      child: Center(
        child: Icon(
          isAudio ? Icons.music_note_rounded : Icons.movie_rounded,
          size: 32,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ExtBadge extends StatelessWidget {
  final String label;
  final ColorScheme cs;

  const _ExtBadge({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: cs.onSecondaryContainer,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
