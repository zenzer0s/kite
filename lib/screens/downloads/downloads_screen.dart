import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../theme/app_theme.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zc = context.zc;
    final downloadsAsync = ref.watch(downloadsProvider);

    return Scaffold(
      backgroundColor: zc.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DOWNLOADS',
                style: GoogleFonts.chakraPetch(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: zc.textPrimary,
                  letterSpacing: 4,
                ),
              ),
              Text(
                'your download history',
                style: GoogleFonts.chakraPetch(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                  color: zc.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: downloadsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: zc.accent),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: GoogleFonts.chakraPetch(color: zc.red),
                    ),
                  ),
                  data: (items) => items.isEmpty
                      ? _EmptyState(zc: zc)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: items.length,
                          itemBuilder: (context, i) =>
                              _DownloadItem(item: items[i], zc: zc, ref: ref),
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

class _EmptyState extends StatelessWidget {
  final ZenithColors zc;
  const _EmptyState({required this.zc});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.download_for_offline_outlined,
            size: 56,
            color: zc.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'NO DOWNLOADS YET',
            style: GoogleFonts.chakraPetch(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: zc.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'your downloads will appear here',
            style: GoogleFonts.chakraPetch(
              fontSize: 12,
              color: zc.textMuted.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadItem extends StatelessWidget {
  final DownloadedItem item;
  final ZenithColors zc;
  final WidgetRef ref;
  const _DownloadItem({
    required this.item,
    required this.zc,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        ref.read(databaseProvider).deleteDownload(item.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: zc.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded, color: zc.red, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: zc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: zc.border),
        ),
        child: Row(
          children: [
            if (item.thumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.thumbnail,
                  width: 72,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (e, o, s) =>
                      Container(width: 72, height: 44, color: zc.surfaceAlt),
                ),
              )
            else
              Container(
                width: 72,
                height: 44,
                decoration: BoxDecoration(
                  color: zc.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.video_file_rounded,
                  color: zc.textMuted,
                  size: 22,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.chakraPetch(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: zc.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _Badge(label: item.ext.toUpperCase(), zc: zc),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.uploader,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.chakraPetch(
                            fontSize: 10,
                            color: zc.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final ZenithColors zc;
  const _Badge({required this.label, required this.zc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: zc.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.chakraPetch(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: zc.accentSoft,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
