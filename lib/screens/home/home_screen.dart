import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(zc: zc),
                const SizedBox(height: 32),
                _UrlInputCard(controller: _urlController, zc: zc),
                const SizedBox(height: 20),
                _FormatSelector(zc: zc),
                const SizedBox(height: 20),
                _DownloadButton(
                  zc: zc,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ZenithColors zc;
  const _Header({required this.zc});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KITE',
          style: GoogleFonts.chakraPetch(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: zc.textPrimary,
            letterSpacing: 4,
          ),
        ),
        Text(
          'paste a link and download',
          style: GoogleFonts.chakraPetch(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            color: zc.textMuted,
          ),
        ),
      ],
    );
  }
}

class _UrlInputCard extends StatelessWidget {
  final TextEditingController controller;
  final ZenithColors zc;
  const _UrlInputCard({required this.controller, required this.zc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: zc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zc.border),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.chakraPetch(fontSize: 14, color: zc.textPrimary),
        decoration: InputDecoration(
          hintText: 'https://youtube.com/watch?v=...',
          hintStyle: GoogleFonts.chakraPetch(fontSize: 13, color: zc.textMuted),
          prefixIcon: Icon(Icons.link_rounded, color: zc.textMuted, size: 20),
          suffixIcon: ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: zc.textMuted,
                      size: 18,
                    ),
                    onPressed: () {
                      controller.clear();
                      HapticFeedback.lightImpact();
                    },
                  ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _FormatSelector extends StatefulWidget {
  final ZenithColors zc;
  const _FormatSelector({required this.zc});

  @override
  State<_FormatSelector> createState() => _FormatSelectorState();
}

class _FormatSelectorState extends State<_FormatSelector> {
  int _selected = 0;
  final List<(String, IconData)> _formats = const [
    ('VIDEO', Icons.movie_rounded),
    ('AUDIO', Icons.music_note_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final zc = widget.zc;
    return Row(
      children: List.generate(_formats.length, (i) {
        final isSelected = _selected == i;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selected = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? zc.accent.withValues(alpha: 0.15)
                    : zc.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? zc.accent.withValues(alpha: 0.5)
                      : zc.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _formats[i].$2,
                    color: isSelected ? zc.accentSoft : zc.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formats[i].$1,
                    style: GoogleFonts.chakraPetch(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isSelected ? zc.accentSoft : zc.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final ZenithColors zc;
  final VoidCallback onTap;
  const _DownloadButton({required this.zc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [zc.accent, zc.accentSoft],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: zc.accent.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'DOWNLOAD',
              style: GoogleFonts.chakraPetch(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
