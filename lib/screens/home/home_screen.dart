import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/download_provider.dart';
import '../../services/download_service.dart';

// Material 3 Dark Color Tokens (Purple Expressive Theme)
const _mdBg = Color(0xFF141218);
const _mdOnBg = Color(0xFFE6E0E9);
const _mdPrimary = Color(0xFFD0BCFF);
const _mdOnPrimary = Color(0xFF381E72);
const _mdPrimaryContainer = Color(0xFF4F378B);
const _mdOnPrimaryContainer = Color(0xFFEADDFF);
const _mdSecondaryContainer = Color(0xFF4A4458);
const _mdOnSecondaryContainer = Color(0xFFE8DEF8);
const _mdSurfaceContainerLow = Color(0xFF1D1B20);
const _mdSurfaceContainer = Color(0xFF211F26);
const _mdSurfaceContainerHigh = Color(0xFF2B2930);
const _mdSurfaceContainerHighest = Color(0xFF36343B);
const _mdOutline = Color(0xFF938F99);
const _mdSuccess = Color(0xFFC4EED0);
const _mdSuccessDark = Color(0xFF1A3320);

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
  bool _isFocused = false;

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
        _isFocused = _focusNode.hasFocus;
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
      builder: (context) => _MediaBottomSheet(onDownloadFormat: _startDownload),
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

  void _startDownload(bool audioOnly) {
    HapticFeedback.mediumImpact();
    ref.read(downloadProvider.notifier).startDownload(audioOnly: audioOnly);
    Navigator.of(context).pop(); // Close sheet
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
          color: _mdBg,
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
                          color: _mdPrimary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kite',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: _mdOnBg,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: _mdOnBg),
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        hoverColor: _mdSurfaceContainerHighest,
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
                          color: _mdOnBg,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Paste a link to grab video or audio',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: _mdOutline,
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
                          color: _mdSurfaceContainerHigh,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: _isFocused ? _mdPrimary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            const Icon(
                              Icons.link_rounded,
                              color: _mdOutline,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _urlController,
                                focusNode: _focusNode,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: _mdOnBg,
                                ),
                                cursorColor: _mdPrimary,
                                onSubmitted: (_) => _fetchInfo(),
                                decoration: InputDecoration(
                                  hintText: 'https://...',
                                  hintStyle: GoogleFonts.outfit(
                                    color: _mdOutline,
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
                                icon: const Icon(
                                  Icons.cancel,
                                  color: _mdOutline,
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
                          icon: const Icon(Icons.paste_rounded, size: 20),
                          label: Text(
                            'Paste from clipboard',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mdSecondaryContainer,
                            foregroundColor: _mdOnSecondaryContainer,
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
                              backgroundColor: _mdPrimary,
                              foregroundColor: _mdOnPrimary,
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
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
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

class _MediaBottomSheet extends ConsumerWidget {
  final Function(bool isAudioOnly) onDownloadFormat;

  const _MediaBottomSheet({required this.onDownloadFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = ref.watch(downloadProvider);
    final isLoading = dl.status == DownloadStatus.fetching || dl.info == null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: _mdSurfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 16),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: _mdOutline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Media Found',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: _mdOnBg,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _mdOnBg),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: _mdSurfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content Box
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: isLoading
                  ? const _SkeletonState()
                  : _DataState(
                      info: dl.info!,
                      onDownloadFormat: onDownloadFormat,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonState extends StatefulWidget {
  const _SkeletonState();

  @override
  State<_SkeletonState> createState() => _SkeletonStateState();
}

class _SkeletonStateState extends State<_SkeletonState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerGradient = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            _mdSurfaceContainerHigh,
            _mdSurfaceContainerHighest,
            _mdSurfaceContainerHigh,
          ],
          stops: [
            (_animation.value - 1).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 1).clamp(0.0, 1.0),
          ],
        );

        Widget shimmerBox(double width, double height, [double radius = 12]) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: shimmerGradient,
              borderRadius: BorderRadius.circular(radius),
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _mdSurfaceContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  shimmerBox(100, 70, 12),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        shimmerBox(double.infinity, 16, 4),
                        const SizedBox(height: 8),
                        shimmerBox(140, 16, 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            shimmerBox(double.infinity, 64, 16),
            const SizedBox(height: 8),
            shimmerBox(double.infinity, 64, 16),
            const SizedBox(height: 8),
            shimmerBox(double.infinity, 64, 16),
          ],
        );
      },
    );
  }
}

class _DataState extends StatelessWidget {
  final VideoInfo info;
  final Function(bool) onDownloadFormat;

  const _DataState({required this.info, required this.onDownloadFormat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Media Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _mdSurfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _mdOutline.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      info.thumbnail,
                      width: 110,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 110,
                        height: 72,
                        color: _mdSurfaceContainerLow,
                      ),
                    ),
                    if (info.duration > 0)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatDuration(info.duration),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _mdOnBg,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.uploader,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: _mdOutline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Video Section
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Video Options',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _mdPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),

        _FormatItem(
          icon: Icons.videocam_rounded,
          iconBg: _mdPrimaryContainer,
          iconColor: _mdOnPrimaryContainer,
          title: '1080p Full HD',
          subtitle: 'MP4 • Includes Audio',
          onTap: () => onDownloadFormat(false),
        ),
        const SizedBox(height: 8),
        _FormatItem(
          icon: Icons.videocam_outlined,
          iconBg: _mdSurfaceContainerHighest,
          iconColor: _mdOnBg,
          title: '720p Standard',
          subtitle: 'MP4 • Includes Audio',
          onTap: () => onDownloadFormat(false),
        ),

        const SizedBox(height: 24),

        // Audio Section
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Audio Only',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _mdSuccess,
              letterSpacing: 0.5,
            ),
          ),
        ),

        _FormatItem(
          icon: Icons.music_note_rounded,
          iconBg: _mdSuccessDark,
          iconColor: _mdSuccess,
          title: 'High Quality Audio',
          subtitle: 'M4A / MP3 Format',
          onTap: () => onDownloadFormat(true),
        ),
      ],
    );
  }
}

class _FormatItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FormatItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _mdSurfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _mdOnBg,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(fontSize: 14, color: _mdOutline),
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

String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
