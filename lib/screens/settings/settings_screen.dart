import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/ytdlp_provider.dart';
import '../about/about_screen.dart';
import '../login/login_screen.dart';
import 'telegram_settings_screen.dart';
import 'widgets/ytdlp_update_bottom_sheet.dart';
import 'app_update_screen.dart';
import 'widgets/settings_widgets.dart';
import '../../providers/update_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeProvider);
    final ytdlp = ref.watch(ytdlpProvider);
    final settings = ref.watch(settingsProvider);
    final update = ref.watch(updateProvider);
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
            SettingsGroup(
              title: 'Engine',
              cs: cs,
              children: [
                SettingsTile(
                  title: 'Engine Updates',
                  subtitle: ytdlpSubtitle,
                  icon: PhosphorIcons.cpu(),
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
                SettingsTile(
                  title: 'App Updates',
                  subtitle: 'v${update.currentVersion}',
                  icon: PhosphorIcons.arrowClockwise(),
                  cs: cs,
                  trailing: Icon(Icons.chevron_right_rounded, color: cs.outline),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AppUpdateScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              title: 'Appearance',
              cs: cs,
              children: [
                SettingsTile(
                  title: 'Dark Mode',
                  subtitle: isDark ? 'Sleek & Professional' : 'Bright & Clear',
                  icon: isDark ? PhosphorIcons.moon() : PhosphorIcons.sun(),
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
            SettingsGroup(
              title: 'Download',
              cs: cs,
              children: [
                SettingsTile(
                  title: 'Download Directory',
                  subtitle: settings.downloadDir,
                  icon: PhosphorIcons.folder(),
                  cs: cs,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.outline,
                  ),
                  onTap: () =>
                      _pickDirectory(context, ref, settings.downloadDir),
                ),
                SettingsTile(
                  title: 'Download Behavior',
                  subtitle: settings.defaultFormat == DefaultFormat.auto
                      ? 'Auto (Best Quality)'
                      : 'Show custom options',
                  icon: settings.defaultFormat == DefaultFormat.auto
                      ? PhosphorIcons.lightning()
                      : PhosphorIcons.listBullets(),
                  cs: cs,
                  onTap: () => _showFormatDialog(context, ref, settings),
                ),
                SettingsTile(
                  title: 'Concurrent Downloads',
                  subtitle: '${settings.concurrentDownloads} simultaneous',
                  icon: PhosphorIcons.stack(),
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
            SettingsGroup(
              title: 'Accounts',
              cs: cs,
              children: [
                SettingsTile(
                  title: 'Instagram',
                  subtitle: settings.kiteCookies?.contains('ds_user_id') == true 
                      ? 'Authenticated' 
                      : 'Log in to download private content',
                  icon: PhosphorIcons.instagramLogo(),
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
                SettingsTile(
                  title: 'YouTube',
                  subtitle: settings.kiteCookies?.contains('SAPISID') == true 
                      ? 'Authenticated' 
                      : 'Log in for member-only content',
                  icon: PhosphorIcons.youtubeLogo(),
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
                SettingsTile(
                  title: 'Sign Out All Accounts',
                  subtitle: settings.kiteCookies != null 
                             ? 'Clear all sessions and flush cookies' 
                             : 'No active session',
                  icon: PhosphorIcons.signOut(),
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
            SettingsGroup(
              title: 'Telegram',
              cs: cs,
              children: [
                SettingsTile(
                  title: 'Telegram Integration',
                  subtitle: settings.telegramUpload
                      ? 'Auto-upload enabled'
                      : 'Configure bot & auto-upload',
                  icon: PhosphorIcons.telegramLogo(),
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
            SettingsGroup(
              title: 'Advanced',
              cs: cs,
              children: [_BatteryOptimizationTile(cs: cs)],
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              title: 'About',
              cs: cs,
              children: [
                SettingsTile(
                  title: 'About Kite',
                  subtitle: 'Developer info, links, and support',
                  icon: PhosphorIcons.info(),
                  cs: cs,
                  trailing: Icon(Icons.chevron_right_rounded, color: cs.outline),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
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
    return SettingsTile(
      title: 'Ignore Battery Optimizations',
      subtitle: _isIgnoring
          ? 'Unrestricted background downloads'
          : 'Allow uninterrupted background downloads',
      icon: PhosphorIcons.batteryChargingVertical(),
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
