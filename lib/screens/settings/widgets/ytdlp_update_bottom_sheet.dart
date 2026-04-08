import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/ytdlp_provider.dart';

class YtdlpUpdateBottomSheet extends ConsumerWidget {
  const YtdlpUpdateBottomSheet({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ytdlp = ref.watch(ytdlpProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.update_rounded, color: cs.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'yt-dlp Engine',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Current: ${ytdlp.version}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: cs.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Update Channel',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 8),
          _ChannelOption(
            title: 'Stable',
            subtitle: 'Recommended for most users',
            value: YtdlpChannel.stable,
            groupValue: ytdlp.channel,
            cs: cs,
            onChanged: (v) => ref.read(ytdlpProvider.notifier).setChannel(v!),
          ),
          _ChannelOption(
            title: 'Nightly',
            subtitle: 'Bleeding edge features & fixes',
            value: YtdlpChannel.nightly,
            groupValue: ytdlp.channel,
            cs: cs,
            onChanged: (v) => ref.read(ytdlpProvider.notifier).setChannel(v!),
          ),
          _ChannelOption(
            title: 'Master',
            subtitle: 'Development branch (Unstable)',
            value: YtdlpChannel.master,
            groupValue: ytdlp.channel,
            cs: cs,
            onChanged: (v) => ref.read(ytdlpProvider.notifier).setChannel(v!),
          ),
          const SizedBox(height: 24),
          Text(
            'Auto-check Frequency',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<YtdlpUpdateInterval>(
                value: ytdlp.interval,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: cs.outline),
                dropdownColor: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                items: YtdlpUpdateInterval.values.map((i) {
                  return DropdownMenuItem(
                    value: i,
                    child: Text(
                      i == YtdlpUpdateInterval.off ? 'Off' : 'Every ${i.name}',
                      style: GoogleFonts.outfit(fontSize: 15, color: cs.onSurface),
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    HapticFeedback.lightImpact();
                    ref.read(ytdlpProvider.notifier).setInterval(v);
                  }
                },
              ),
            ),
          ),
          const Divider(height: 48),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last check:',
                      style: GoogleFonts.outfit(fontSize: 12, color: cs.outline),
                    ),
                    Text(
                      _formatDate(ytdlp.lastUpdateTime),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: ytdlp.isUpdating
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        ref.read(ytdlpProvider.notifier).update();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: ytdlp.isUpdating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  ytdlp.isUpdating ? 'Updating...' : 'Check Now',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (ytdlp.lastStatus != null || ytdlp.lastError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ytdlp.lastError != null
                    ? cs.errorContainer.withValues(alpha: 0.3)
                    : cs.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    ytdlp.lastError != null
                        ? Icons.error_outline_rounded
                        : Icons.info_outline_rounded,
                    size: 18,
                    color: ytdlp.lastError != null ? cs.error : cs.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ytdlp.lastError ?? ytdlp.lastStatus!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: ytdlp.lastError != null ? cs.error : cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChannelOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final YtdlpChannel value;
  final YtdlpChannel groupValue;
  final ColorScheme cs;
  final ValueChanged<YtdlpChannel?> onChanged;

  const _ChannelOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.cs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? cs.primaryContainer.withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: cs.outline,
                    ),
                  ),
                ],
              ),
            ),
            Radio<YtdlpChannel>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: cs.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
