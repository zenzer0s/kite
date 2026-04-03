import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';
import '../../providers/ytdlp_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeProvider);
    final ytdlp = ref.watch(ytdlpProvider);
    final isDark = themeMode == ThemeMode.dark;
    final ytdlpSubtitle = ytdlp.isUpdating
        ? 'Checking for updates...'
        : ytdlp.lastStatus == null
        ? ytdlp.version
        : '${ytdlp.version} · ${ytdlp.lastStatus}';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          physics: const BouncingScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Settings',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            _SettingsGroup(
              title: 'Appearance',
              cs: cs,
              children: [
                _SettingsTile(
                  title: 'Dark Mode',
                  subtitle: isDark ? 'Sleek & Professional' : 'Bright & Clear',
                  icon: isDark
                      ? Icons.nightlight_round
                      : Icons.wb_sunny_rounded,
                  cs: cs,
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) {
                      HapticFeedback.mediumImpact();
                      ref.read(themeProvider.notifier).toggle();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'Download',
              cs: cs,
              children: [
                _SettingsTile(
                  title: 'Download Directory',
                  subtitle: '/storage/emulated/0/Download',
                  icon: Icons.folder_rounded,
                  cs: cs,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.outline,
                  ),
                  onTap: () {},
                ),
                _SettingsTile(
                  title: 'Default Format',
                  subtitle: 'Best quality (auto)',
                  icon: Icons.high_quality_rounded,
                  cs: cs,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.outline,
                  ),
                  onTap: () {},
                ),
                _SettingsTile(
                  title: 'Concurrent Downloads',
                  subtitle: '3 simultaneous',
                  icon: Icons.download_for_offline_rounded,
                  cs: cs,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.outline,
                  ),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'About',
              cs: cs,
              children: [
                _SettingsTile(
                  title: 'Version',
                  subtitle: '1.0.0',
                  icon: Icons.info_outline_rounded,
                  cs: cs,
                ),
                _SettingsTile(
                  title: 'Auto-update yt-dlp',
                  subtitle: 'Check for updates in background',
                  icon: Icons.update_rounded,
                  cs: cs,
                  trailing: Switch(
                    value: ytdlp.autoUpdate,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      ref.read(ytdlpProvider.notifier).toggleAutoUpdate(val);
                    },
                  ),
                ),
                _SettingsTile(
                  title: 'yt-dlp Version',
                  subtitle: ytdlpSubtitle,
                  icon: Icons.terminal_rounded,
                  cs: cs,
                  trailing: Icon(Icons.refresh_rounded, color: cs.outline),
                  onTap: () {
                    if (!ytdlp.isUpdating) {
                      HapticFeedback.lightImpact();
                      ref.read(ytdlpProvider.notifier).update();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final ColorScheme cs;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.cs,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: children
                  .asMap()
                  .entries
                  .map(
                    (e) => Column(
                      children: [
                        e.value,
                        if (e.key < children.length - 1)
                          Divider(
                            height: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                            indent: 66,
                          ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ColorScheme cs;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.cs,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cs.onPrimaryContainer, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(fontSize: 12, color: cs.outline),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
