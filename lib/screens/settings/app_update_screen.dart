import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/settings_provider.dart';
import '../../providers/update_provider.dart';
import 'widgets/settings_widgets.dart';

class AppUpdateScreen extends ConsumerWidget {
  const AppUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final updateState = ref.watch(updateProvider);
    final settings = ref.watch(settingsProvider);
    final updateNotifier = ref.read(updateProvider.notifier);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft(), color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'App Updates',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        children: [
          // Version Status Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.arrowClockwise(),
                    size: 48,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  updateState.update?.isUpdateAvailable == true
                      ? 'Update Available!'
                      : 'Kite is Up to Date',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Version: v${updateState.currentVersion}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: cs.outline,
                  ),
                ),
                if (updateState.update?.isUpdateAvailable == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Latest: v${updateState.update!.version}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SettingsGroup(
            title: 'General',
            cs: cs,
            children: [
              SettingsTile(
                title: 'Auto Check for Updates',
                subtitle: 'Notify when a new version is released',
                icon: PhosphorIcons.notification(),
                cs: cs,
                trailing: Switch(
                  value: settings.autoCheckUpdates,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    ref.read(settingsProvider.notifier).setAutoCheckUpdates(val);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          SettingsGroup(
            title: 'Release Details',
            cs: cs,
            children: [
              SettingsTile(
                title: 'Check for Updates',
                subtitle: updateState.isLoading ? 'Searching...' : 'Pull latest info from GitHub',
                icon: PhosphorIcons.arrowsClockwise(),
                cs: cs,
                onTap: updateState.isLoading ? null : () {
                  HapticFeedback.mediumImpact();
                  updateNotifier.checkForUpdates();
                },
                trailing: updateState.isLoading 
                  ? SizedBox(
                      width: 16, 
                      height: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)
                    )
                  : null,
              ),
              SettingsTile(
                title: 'Changelog',
                subtitle: updateState.update?.changelog.isNotEmpty == true 
                    ? updateState.update!.changelog.split('\n').first 
                    : 'See what\'s new in the latest version',
                icon: PhosphorIcons.article(),
                cs: cs,
                onTap: () {
                  if (updateState.update != null) {
                    _showChangelog(context, updateState.update!.version, updateState.update!.changelog);
                  } else {
                    updateNotifier.checkForUpdates();
                  }
                },
              ),
              SettingsTile(
                title: 'Latest Commit',
                subtitle: (updateState.update?.commitSha != null && updateState.update!.commitSha.length >= 7)
                    ? updateState.update!.commitSha.toUpperCase().substring(0, 7)
                    : 'Verify build source on GitHub',
                icon: PhosphorIcons.gitCommit(),
                cs: cs,
                onTap: () {
                  if (updateState.update != null) {
                    launchUrl(Uri.parse(updateState.update!.commitUrl));
                  }
                },
              ),
            ],
          ),

          if (updateState.error != null) ...[
            const SizedBox(height: 20),
            Center(
              child: Text(
                updateState.error!,
                style: GoogleFonts.outfit(color: cs.error, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: updateState.update?.isUpdateAvailable == true
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton.icon(
                  onPressed: () => launchUrl(Uri.parse(updateState.update!.downloadUrl)),
                  icon: Icon(PhosphorIcons.downloadSimple()),
                  label: Text('Download v${updateState.update!.version}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _showChangelog(BuildContext context, String version, String body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'v$version',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(PhosphorIcons.x()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    body,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      height: 1.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
