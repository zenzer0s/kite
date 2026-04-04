import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/download_provider.dart';
import '../../providers/settings_provider.dart';
import '../settings/settings_screen.dart';
import 'media_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _shareChannel = EventChannel('com.zenzer0s.kite/share');

  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isInputFilled = false;
  bool _isSheetOpen = false;
  late final AnimationController _sheetCtrl;

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _urlController.addListener(() {
      setState(() {
        _isInputFilled = _urlController.text.trim().isNotEmpty;
      });
    });
    _focusNode.addListener(() {
      setState(() {});
    });
    _shareChannel.receiveBroadcastStream().listen((url) {
      if (url is String && url.isNotEmpty) {
        _fetchInfoFromUrl(url);
      }
    });
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _fetchInfo() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    await _fetchInfoFromUrl(url);
  }

  Future<void> _fetchInfoFromUrl(String url) async {
    if (_isSheetOpen) return;
    _urlController.text = url;
    HapticFeedback.lightImpact();

    final isAuto = ref.read(settingsProvider).defaultFormat == DefaultFormat.auto;

    if (isAuto) {
      final info = await ref.read(downloadProvider.notifier).fetchInfo(url);
      if (info == null) return;
      HapticFeedback.mediumImpact();
      ref.read(downloadsProvider.notifier).startDownload(
            info: info,
            audioOnly: false,
          );
      if (mounted) _urlController.clear();
      ref.read(downloadProvider.notifier).reset();
    } else {
      // Trigger fetch in background
      ref.read(downloadProvider.notifier).fetchInfo(url);
      
      // Open sheet instantly!
      setState(() => _isSheetOpen = true);
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        transitionAnimationController: _sheetCtrl,
        builder: (context) => MediaBottomSheet(
          isTransparentOverlay: false,
          onDownload: _startDownload,
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _isSheetOpen = false;
          });
        }
        final dl = ref.read(downloadProvider);
        if (dl.status == DownloadStatus.idle ||
            dl.status == DownloadStatus.error) {
          if (mounted) _urlController.clear();
        }
        ref.read(downloadProvider.notifier).reset();
      });
    }
  }

  void _startDownload({required bool audioOnly, String? formatId}) {
    HapticFeedback.mediumImpact();
    final info = ref.read(downloadProvider).info;
    if (info == null) return;
    ref
        .read(downloadsProvider.notifier)
        .startDownload(info: info, audioOnly: audioOnly, formatId: formatId);
    _urlController.clear();
    Navigator.of(context).pop();
  }

  void _pasteFromClipboard() async {
    HapticFeedback.selectionClick();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _urlController.text = data.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dl = ref.watch(downloadProvider);
    final tasks = ref.watch(downloadsProvider);
    final isFetching = dl.status == DownloadStatus.fetching;
    final activeTasks = tasks.values.toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: _isSheetOpen ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          final scale = 1.0 - 0.04 * t;
          final translateY = -24.0 * t;
          final radius = 32.0 * t;
          return Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..translate(0.0, translateY)
              ..scale(scale),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: child,
            ),
          );
        },
        child: Container(
          color: cs.surface,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.paperPlaneTilt(
                              PhosphorIconsStyle.fill,
                            ),
                            color: cs.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kite',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings_outlined,
                          color: cs.onSurface,
                        ),
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: activeTasks.isEmpty
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        if (activeTasks.isEmpty) ...[
                          Text(
                            'Download Media',
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                              height: 1.2,
                              color: cs.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Paste a link to grab video or audio',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: cs.outline,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                        ] else
                          const SizedBox(height: 16),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 64,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: isFetching ? cs.secondary : cs.primary,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 20),
                              Icon(
                                isFetching
                                    ? Icons.hourglass_top_rounded
                                    : Icons.link_rounded,
                                color: isFetching ? cs.secondary : cs.outline,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _urlController,
                                  focusNode: _focusNode,
                                  enabled: !isFetching,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    color: cs.onSurface,
                                  ),
                                  cursorColor: cs.primary,
                                  onSubmitted: (_) => _fetchInfo(),
                                  decoration: InputDecoration(
                                    hintText: isFetching
                                        ? 'Fetching info\u2026'
                                        : 'https://...',
                                    hintStyle: GoogleFonts.outfit(
                                      color: cs.outline,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              if (_isInputFilled && !isFetching)
                                IconButton(
                                  icon: Icon(
                                    Icons.cancel,
                                    color: cs.outline,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    _urlController.clear();
                                    _focusNode.requestFocus();
                                  },
                                ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: !_isInputFilled && !isFetching
                              ? ElevatedButton.icon(
                                  key: const ValueKey('paste'),
                                  onPressed: _pasteFromClipboard,
                                  icon: const Icon(
                                    Icons.paste_rounded,
                                    size: 20,
                                  ),
                                  label: Text(
                                    'Paste from clipboard',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.secondaryContainer,
                                    foregroundColor: cs.onSecondaryContainer,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  key: const ValueKey('download'),
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: isFetching ? null : _fetchInfo,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFetching
                                          ? cs.surfaceContainerHighest
                                          : cs.primary,
                                      foregroundColor: isFetching
                                          ? cs.outline
                                          : cs.onPrimary,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (isFetching) ...[
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: cs.secondary,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Fetching\u2026',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            'Download',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        if (activeTasks.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Expanded(
                            child: ListView.separated(
                              itemCount: activeTasks.length,
                              separatorBuilder: (context, i) =>
                                  const SizedBox(height: 10),
                              padding: const EdgeInsets.only(bottom: 100),
                              itemBuilder: (context, i) {
                                final task = activeTasks[i];
                                return _TaskCard(
                                  key: ValueKey(task.taskId),
                                  task: task,
                                  cs: cs,
                                  onPause: () => ref
                                      .read(downloadsProvider.notifier)
                                      .pauseTask(task.taskId),
                                  onResume: () => ref
                                      .read(downloadsProvider.notifier)
                                      .resumeTask(task.taskId),
                                  onCancel: () => ref
                                      .read(downloadsProvider.notifier)
                                      .cancelTask(task.taskId),
                                  onDismiss: () => ref
                                      .read(downloadsProvider.notifier)
                                      .dismissTask(task.taskId),
                                );
                              },
                            ),
                          ),
                        ] else
                          const SizedBox(height: 96),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DownloadTask task;
  final ColorScheme cs;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;

  const _TaskCard({
    super.key,
    required this.task,
    required this.cs,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == DownloadStatus.done;
    final isError = task.status == DownloadStatus.error;
    final isPaused = task.status == DownloadStatus.paused;
    final isActive = task.status == DownloadStatus.downloading;
    final progress = (task.progress / 100).clamp(0.0, 1.0);

    Color accentColor;
    Color accentBg;
    IconData statusIcon;
    String statusLabel;

    if (isError) {
      accentColor = cs.error;
      accentBg = cs.errorContainer;
      statusIcon = Icons.error_outline_rounded;
      statusLabel = 'Failed';
    } else if (isDone) {
      accentColor = cs.primary;
      accentBg = cs.primaryContainer;
      statusIcon = Icons.check_circle_outline_rounded;
      statusLabel = 'Complete';
    } else if (isPaused) {
      accentColor = cs.tertiary;
      accentBg = cs.tertiaryContainer;
      statusIcon = Icons.pause_circle_outline_rounded;
      statusLabel = 'Paused';
    } else {
      accentColor = cs.secondary;
      accentBg = cs.secondaryContainer;
      statusIcon = Icons.downloading_rounded;
      statusLabel = 'Downloading';
    }

    return Dismissible(
      key: ValueKey('dismiss_${task.taskId}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        if (isActive || isPaused) {
          onCancel();
        } else {
          onDismiss();
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, size: 18, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          isError
                              ? (task.errorMessage ?? 'Unknown error')
                              : task.info.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        if (task.info.uploader.isNotEmpty && !isError)
                          Text(
                            task.info.uploader,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: cs.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isActive || isPaused) ...[
                    _IconBtn(
                      icon: isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: isPaused ? cs.tertiary : cs.secondary,
                      bg: isPaused
                          ? cs.tertiaryContainer
                          : cs.secondaryContainer,
                      onTap: isPaused ? onResume : onPause,
                    ),
                    const SizedBox(width: 6),
                    _IconBtn(
                      icon: Icons.close_rounded,
                      color: cs.error,
                      bg: cs.errorContainer,
                      onTap: onCancel,
                    ),
                  ] else
                    _IconBtn(
                      icon: Icons.check_rounded,
                      color: accentColor,
                      bg: accentBg,
                      onTap: onDismiss,
                    ),
                ],
              ),
            ),
            if (!isError) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: isDone ? 1.0 : progress,
                    minHeight: 4,
                    backgroundColor: cs.outlineVariant.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPaused
                          ? accentColor.withValues(alpha: 0.45)
                          : accentColor,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                child: Row(
                  children: [
                    if (task.currentLine != null && !isDone)
                      Expanded(
                        child: Text(
                          task.currentLine!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: cs.outline,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    Text(
                      isDone ? '100%' : '${task.progress.toStringAsFixed(0)}%',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
