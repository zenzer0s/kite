import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';
import '../../providers/ytdlp_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zc = context.zc;
    final themeMode = ref.watch(themeProvider);
    final ytdlp = ref.watch(ytdlpProvider);
    final isDark = themeMode == ThemeMode.dark;
    final ytdlpSubtitle = ytdlp.isUpdating
        ? 'Checking for updates...'
        : ytdlp.lastStatus == null
        ? ytdlp.version
        : '${ytdlp.version} • ${ytdlp.lastStatus}';

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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            physics: const BouncingScrollPhysics(),
            children: [
              Text(
                'SETTINGS',
                style: GoogleFonts.chakraPetch(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: zc.textPrimary,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'configure kite',
                style: GoogleFonts.chakraPetch(
                  fontSize: 12,
                  color: zc.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _SettingsGroup(
                title: 'APPEARANCE',
                zc: zc,
                children: [
                  _SettingsTile(
                    title: 'Dark Mode',
                    subtitle: isDark
                        ? 'Sleek & Professional'
                        : 'Bright & Clear',
                    icon: isDark
                        ? Icons.nightlight_round
                        : Icons.wb_sunny_rounded,
                    zc: zc,
                    trailing: _KiteToggle(
                      value: isDark,
                      onChanged: (_) {
                        HapticFeedback.mediumImpact();
                        ref.read(themeProvider.notifier).toggle();
                      },
                      zc: zc,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsGroup(
                title: 'DOWNLOAD',
                zc: zc,
                children: [
                  _SettingsTile(
                    title: 'Download Directory',
                    subtitle: '/storage/emulated/0/Download',
                    icon: Icons.folder_rounded,
                    zc: zc,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: zc.textDim,
                    ),
                    onTap: () {},
                  ),
                  _SettingsTile(
                    title: 'Default Format',
                    subtitle: 'Best quality (auto)',
                    icon: Icons.high_quality_rounded,
                    zc: zc,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: zc.textDim,
                    ),
                    onTap: () {},
                  ),
                  _SettingsTile(
                    title: 'Concurrent Downloads',
                    subtitle: '3 simultaneous',
                    icon: Icons.download_for_offline_rounded,
                    zc: zc,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: zc.textDim,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsGroup(
                title: 'ABOUT',
                zc: zc,
                children: [
                  _SettingsTile(
                    title: 'Version',
                    subtitle: '1.0.0',
                    icon: Icons.info_outline_rounded,
                    zc: zc,
                  ),
                  _SettingsTile(
                    title: 'Auto-update yt-dlp',
                    subtitle: 'Check for updates in background',
                    icon: Icons.update_rounded,
                    zc: zc,
                    trailing: _KiteToggle(
                      value: ytdlp.autoUpdate,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        ref.read(ytdlpProvider.notifier).toggleAutoUpdate(val);
                      },
                      zc: zc,
                    ),
                  ),
                  _SettingsTile(
                    title: 'yt-dlp Version',
                    subtitle: ytdlpSubtitle,
                    icon: Icons.terminal_rounded,
                    zc: zc,
                    trailing: Icon(Icons.refresh_rounded, color: zc.textDim),
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
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final ZenithColors zc;
  final List<Widget> children;
  const _SettingsGroup({
    required this.title,
    required this.zc,
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
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ZenithColors zc;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.zc,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: zc.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: zc.accentSoft, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
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
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _KiteToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final ZenithColors zc;
  const _KiteToggle({
    required this.value,
    required this.onChanged,
    required this.zc,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          color: value ? zc.accent : zc.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: value ? zc.accent : zc.border),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
