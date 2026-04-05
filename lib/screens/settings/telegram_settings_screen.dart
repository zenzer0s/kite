import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/settings_provider.dart';
import '../../services/download_service.dart';

class TelegramSettingsScreen extends ConsumerStatefulWidget {
  const TelegramSettingsScreen({super.key});

  @override
  ConsumerState<TelegramSettingsScreen> createState() =>
      _TelegramSettingsScreenState();
}

class _TelegramSettingsScreenState
    extends ConsumerState<TelegramSettingsScreen> {
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);

    final tokenConfigured = settings.telegramBotToken.isNotEmpty;
    final chatConfigured = settings.telegramChatId.isNotEmpty;
    final fullyConfigured = settings.telegramFullyConfigured;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          physics: const BouncingScrollPhysics(),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Telegram',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Info banner
            _InfoBanner(cs: cs),

            const SizedBox(height: 20),

            // Fast Mode section
            _SectionLabel(label: 'Fast Mode', cs: cs),
            const SizedBox(height: 8),
            _SettingsGroup(
              cs: cs,
              children: [
                _SwitchTile(
                  title: 'Fast Mode',
                  subtitle: 'Share directly to Telegram instead of downloading locally',
                  icon: Icons.send_rounded,
                  cs: cs,
                  value: settings.fastMode,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    ref.read(settingsProvider.notifier).setFastMode(v);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Telegram Cloud section
            _SectionLabel(label: 'Telegram Cloud', cs: cs),
            const SizedBox(height: 8),
            _SettingsGroup(
              cs: cs,
              children: [
                _SwitchTile(
                  title: 'Auto-upload to Telegram',
                  subtitle: fullyConfigured
                      ? 'Upload completed downloads to your chat'
                      : 'Configure bot token and chat ID first',
                  icon: Icons.cloud_upload_rounded,
                  cs: cs,
                  value: settings.telegramUpload,
                  enabled: fullyConfigured,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    ref.read(settingsProvider.notifier).setTelegramUpload(v);
                  },
                ),
                _ActionTile(
                  title: 'Bot Token',
                  subtitle: tokenConfigured
                      ? _maskToken(settings.telegramBotToken)
                      : 'Tap to set',
                  icon: Icons.key_rounded,
                  cs: cs,
                  onTap: () => _showTokenDialog(context, ref, settings.telegramBotToken),
                ),
                _ActionTile(
                  title: 'Chat ID',
                  subtitle: chatConfigured ? settings.telegramChatId : 'Tap to set',
                  icon: Icons.tag_rounded,
                  cs: cs,
                  onTap: () => _showChatIdDialog(context, ref, settings.telegramChatId),
                ),
                _ActionTile(
                  title: 'Test Connection',
                  subtitle: fullyConfigured
                      ? 'Send a test message to verify setup'
                      : 'Set token and chat ID first',
                  icon: Icons.bolt_rounded,
                  cs: cs,
                  enabled: fullyConfigured && !_isTesting,
                  trailing: _isTesting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        )
                      : Icon(Icons.chevron_right_rounded, color: cs.outline),
                  onTap: () => _testConnection(context, ref, settings),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Help card
            _HelpCard(cs: cs),
          ],
        ),
      ),
    );
  }

  String _maskToken(String token) {
    if (token.length <= 8) return '••••••••';
    return '${token.substring(0, 4)}••••••••${token.substring(token.length - 4)}';
  }

  Future<void> _showTokenDialog(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _TextInputDialog(
        title: 'Bot Token',
        icon: Icons.key_rounded,
        initialValue: current,
        hintText: 'e.g. 123456789:AAF...',
        supportingText: 'Get a token from @BotFather on Telegram',
        obscure: true,
        keyboardType: TextInputType.visiblePassword,
      ),
    );
    if (result != null) {
      await ref.read(settingsProvider.notifier).setTelegramBotToken(result);
    }
  }

  Future<void> _showChatIdDialog(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _TextInputDialog(
        title: 'Chat ID',
        icon: Icons.tag_rounded,
        initialValue: current,
        hintText: 'e.g. -1001234567890',
        supportingText: 'Your user ID, group ID, or channel ID',
        obscure: false,
        keyboardType: TextInputType.text,
      ),
    );
    if (result != null) {
      await ref.read(settingsProvider.notifier).setTelegramChatId(result);
    }
  }

  Future<void> _testConnection(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    HapticFeedback.mediumImpact();
    setState(() => _isTesting = true);
    try {
      final res = await DownloadService.testTelegramConnection(
        token: settings.telegramBotToken,
        chatId: settings.telegramChatId,
      );
      if (!context.mounted) return;
      final success = res['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Connected! Check your Telegram.'
                : '❌ ${res['error'] ?? 'Connection failed'}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              success ? Colors.green.shade700 : Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }
}

// ─────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final ColorScheme cs;
  const _InfoBanner({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: cs.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Connect a Telegram bot to automatically receive your downloaded '
              'files in a chat. Files up to 50 MB are supported.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final ColorScheme cs;
  const _HelpCard({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to set up',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 10),
          ..._steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.$1,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.$2,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _steps = [
    ('1.', 'Open Telegram and search for @BotFather'),
    ('2.', 'Send /newbot and follow the instructions to create your bot'),
    ('3.', 'Copy the bot token and paste it above'),
    ('4.', 'Add the bot to your chat / channel as an admin'),
    ('5.', 'Get your chat ID (e.g. via @userinfobot) and paste it above'),
    ('6.', 'Press "Test Connection" to verify everything works'),
  ];
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _SectionLabel({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 0),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final ColorScheme cs;
  final List<Widget> children;
  const _SettingsGroup({required this.cs, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final ColorScheme cs;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.cs,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _IconBox(icon: icon, cs: cs),
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
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final ColorScheme cs;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget? trailing;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.cs,
    this.onTap,
    this.enabled = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _IconBox(icon: icon, cs: cs),
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
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: cs.outline,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right_rounded, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final ColorScheme cs;
  const _IconBox({required this.icon, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: cs.onPrimaryContainer, size: 18),
    );
  }
}

// ─────────────────────────────────────────────
// Text input dialog (token / chat ID)
// ─────────────────────────────────────────────

class _TextInputDialog extends StatefulWidget {
  final String title;
  final IconData icon;
  final String initialValue;
  final String hintText;
  final String supportingText;
  final bool obscure;
  final TextInputType keyboardType;

  const _TextInputDialog({
    required this.title,
    required this.icon,
    required this.initialValue,
    required this.hintText,
    required this.supportingText,
    required this.obscure,
    required this.keyboardType,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _showClear = widget.initialValue.isNotEmpty;
    _controller.addListener(() {
      setState(() => _showClear = _controller.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(widget.icon),
      title: Text(
        widget.title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            obscureText: widget.obscure,
            keyboardType: widget.keyboardType,
            decoration: InputDecoration(
              hintText: widget.hintText,
              suffixIcon: _showClear
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _controller.clear(),
                    )
                  : null,
            ),
            autofocus: true,
            onSubmitted: (_) => Navigator.of(context).pop(_controller.text.trim()),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.supportingText,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: cs.outline,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
