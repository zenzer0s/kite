import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/ytdlp_provider.dart';
import '../login/login_screen.dart';
import 'telegram_settings_screen.dart';
import 'widgets/ytdlp_update_bottom_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeProvider);
    final ytdlp = ref.watch(ytdlpProvider);
    final settings = ref.watch(settingsProvider);
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
                  subtitle: settings.downloadDir,
                  icon: Icons.folder_rounded,
                  cs: cs,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.outline,
                  ),
                  onTap: () =>
                      _pickDirectory(context, ref, settings.downloadDir),
                ),
                _SettingsTile(
                  title: 'Download Behavior',
                  subtitle: settings.defaultFormat == DefaultFormat.auto
                      ? 'Auto (Best Quality)'
                      : 'Show custom options',
                  icon: settings.defaultFormat == DefaultFormat.auto
                      ? Icons.flash_on_rounded
                      : Icons.list_alt_rounded,
                  cs: cs,
                  onTap: () => _showFormatDialog(context, ref, settings),
                ),
                _SettingsTile(
                  title: 'Concurrent Downloads',
                  subtitle: '${settings.concurrentDownloads} simultaneous',
                  icon: Icons.download_for_offline_rounded,
                  cs: cs,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.outline,
                  ),
                  onTap: () => _pickConcurrent(
                    context,
                    ref,
                    settings.concurrentDownloads,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'Accounts',
              cs: cs,
              children: [
                _SettingsTile(
                  title: 'Instagram',
                  subtitle: settings.kiteCookies?.contains('ds_user_id') == true 
                      ? 'Authenticated' 
                      : 'Log in to download private content',
                  icon: Icons.camera_alt_rounded,
                  cs: cs,
                  trailing: settings.kiteCookies?.contains('ds_user_id') == true
                      ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
                      : Icon(Icons.chevron_right_rounded, color: cs.outline),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(
                        title: 'Instagram Login',
                        initialUrl: 'https://www.instagram.com/accounts/login/',
                      ),
                    ),
                  ),
                ),
                _SettingsTile(
                  title: 'YouTube',
                  subtitle: settings.kiteCookies?.contains('SAPISID') == true 
                      ? 'Authenticated' 
                      : 'Log in for member-only content',
                  icon: Icons.play_circle_fill_rounded,
                  cs: cs,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(
                        title: 'YouTube Login',
                        initialUrl: 'https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fwww.youtube.com',
                      ),
                    ),
                  ),
                ),
                _SettingsTile(
                  title: 'Sign Out All Accounts',
                  subtitle: settings.kiteCookies != null 
                             ? 'Clear all sessions and flush cookies' 
                             : 'No active session',
                  icon: Icons.logout_rounded,
                  cs: cs,
                  onTap: settings.kiteCookies == null ? null : () async {
                    final confirmed = await showAdaptiveDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog.adaptive(
                        title: Text('Sign Out?', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        content: Text('This will clear all Instagram and YouTube sessions and flush browser cookies natively.', style: GoogleFonts.outfit(fontSize: 14)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Cancel', style: GoogleFonts.outfit(color: cs.outline)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('Sign Out', style: GoogleFonts.outfit(color: cs.error, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      const platform = MethodChannel('com.zenzer0s.kite/downloader');
                      try {
                        HapticFeedback.mediumImpact();
                        await platform.invokeMethod('clearCookies');
                        await ref.read(settingsProvider.notifier).setCookies(null);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🎉 Session cleared!', style: GoogleFonts.outfit()),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: cs.secondary,
                            ),
                          );
                        }
                      } catch (e) {
                        // Silent fail
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'Telegram',
              cs: cs,
              children: [
                _SettingsTile(
                  title: 'Telegram Integration',
                  subtitle: settings.telegramUpload
                      ? 'Auto-upload enabled'
                      : 'Configure bot & auto-upload',
                  icon: Icons.send_rounded,
                  cs: cs,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.outline,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TelegramSettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'Advanced',
              cs: cs,
              children: [_BatteryOptimizationTile(cs: cs)],
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
                  title: 'yt-dlp Engine',
                  subtitle: ytdlpSubtitle,
                  icon: Icons.terminal_rounded,
                  cs: cs,
                  trailing: Icon(Icons.chevron_right_rounded, color: cs.outline),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const YtdlpUpdateBottomSheet(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDirectory(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Download Folder',
      initialDirectory: current,
    );
    if (path != null) {
      ref.read(settingsProvider.notifier).setDownloadDir(path);
    }
  }

  Future<void> _showFormatDialog(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final result = await showModalBottomSheet<DefaultFormat>(
      context: context,
      backgroundColor: cs.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default Format',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                RadioGroup<DefaultFormat>(
                  groupValue: settings.defaultFormat,
                  onChanged: (v) {
                    if (v != null) Navigator.pop(context, v);
                  },
                  child: Column(
                    children: [
                      RadioListTile<DefaultFormat>(
                        title: Text('Auto', style: GoogleFonts.outfit()),
                        subtitle: Text(
                          'Instantly download the best video & audio',
                          style: GoogleFonts.outfit(fontSize: 12),
                        ),
                        value: DefaultFormat.auto,
                        activeColor: cs.primary,
                      ),
                      RadioListTile<DefaultFormat>(
                        title: Text('Custom', style: GoogleFonts.outfit()),
                        subtitle: Text(
                          'Always pick quality and format from a list',
                          style: GoogleFonts.outfit(fontSize: 12),
                        ),
                        value: DefaultFormat.custom,
                        activeColor: cs.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) {
      ref.read(settingsProvider.notifier).setDefaultFormat(result);
    }
  }

  Future<void> _pickConcurrent(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Concurrent Downloads',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(5, (i) {
                    final n = i + 1;
                    final selected = n == current;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(settingsProvider.notifier)
                            .setConcurrentDownloads(n);
                        Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primary
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$n',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: selected ? cs.onPrimary : cs.onSurface,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
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
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _BatteryOptimizationTile extends StatefulWidget {
  final ColorScheme cs;

  const _BatteryOptimizationTile({required this.cs});

  @override
  State<_BatteryOptimizationTile> createState() =>
      _BatteryOptimizationTileState();
}

class _BatteryOptimizationTileState extends State<_BatteryOptimizationTile> {
  static const platform = MethodChannel('com.zenzer0s.kite/downloader');
  bool _isIgnoring = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final bool result = await platform.invokeMethod(
        'isIgnoringBatteryOptimizations',
      );
      if (mounted) setState(() => _isIgnoring = result);
    } catch (_) {}
  }

  Future<void> _requestIgnore() async {
    try {
      await platform.invokeMethod('requestIgnoreBatteryOptimizations');
      await Future.delayed(const Duration(seconds: 1));
      _checkStatus();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      title: 'Ignore Battery Optimizations',
      subtitle: _isIgnoring
          ? 'Unrestricted background downloads'
          : 'Allow uninterrupted background downloads',
      icon: Icons.battery_charging_full_rounded,
      cs: widget.cs,
      trailing: Switch(
        value: _isIgnoring,
        onChanged: (val) {
          HapticFeedback.lightImpact();
          _requestIgnore();
        },
      ),
    );
  }
}
