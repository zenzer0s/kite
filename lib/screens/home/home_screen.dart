import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/download_provider.dart';
import 'media_bottom_sheet.dart';

// Material 3 Dark Color Tokens (Purple Expressive Theme)

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isInputFilled = false;
  bool _isSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(() {
      setState(() {
        _isInputFilled = _urlController.text.trim().isNotEmpty;
      });
    });
    _focusNode.addListener(() {
      setState(() {
      });
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _fetchInfo() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    HapticFeedback.lightImpact();
    // Start fetching
    ref.read(downloadProvider.notifier).fetchInfo(url);

    // Show Bottom Sheet immediately
    setState(() {
      _isSheetOpen = true;
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => MediaBottomSheet(onDownload: _startDownload),
    ).then((_) {
      setState(() {
        _isSheetOpen = false;
      });
      // Clear input after sheet closes successfully on start
      final dl = ref.read(downloadProvider);
      if (dl.status == DownloadStatus.downloading) {
        _urlController.clear();
      }
    });
  }

  void _startDownload({required bool audioOnly, String? formatId}) {
    HapticFeedback.mediumImpact();
    ref
        .read(downloadProvider.notifier)
        .startDownload(audioOnly: audioOnly, formatId: formatId);
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(
          _isSheetOpen ? 0.96 : 1.0,
          _isSheetOpen ? 0.96 : 1.0,
          1.0,
        )..setTranslationRaw(0.0, _isSheetOpen ? -24.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: _isSheetOpen
              ? BorderRadius.circular(32)
              : BorderRadius.zero,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kite',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        hoverColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Download Media',
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          height: 1.2,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Paste a link to grab video or audio',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.outline,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Input Bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 64,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            Icon(
                              Icons.link_rounded,
                              color: Theme.of(context).colorScheme.outline,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _urlController,
                                focusNode: _focusNode,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                cursorColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                onSubmitted: (_) => _fetchInfo(),
                                decoration: InputDecoration(
                                  hintText: 'https://...',
                                  hintStyle: GoogleFonts.outfit(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
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
                            if (_isInputFilled)
                              IconButton(
                                icon: Icon(
                                  Icons.cancel,
                                  color: Theme.of(context).colorScheme.outline,
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
                      const SizedBox(height: 24),

                      // Action Buttons
                      if (!_isInputFilled)
                        ElevatedButton.icon(
                          onPressed: _pasteFromClipboard,
                          icon: Icon(Icons.paste_rounded, size: 20),
                          label: Text(
                            'Paste from clipboard',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
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
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _fetchInfo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Download',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 96), // Bottom offset
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
