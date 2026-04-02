import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOWNLOADS',
                            style: GoogleFonts.chakraPetch(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: zc.textPrimary,
                              letterSpacing: 3,
                            ),
                          ),
                          Text(
                            'your download history',
                            style: GoogleFonts.chakraPetch(
                              fontSize: 12,
                              color: zc.textMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.search_rounded, color: zc.textMuted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: zc.textDim,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'NO DOWNLOADS YET',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: zc.textDim,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'paste a link on the home tab',
                        style: GoogleFonts.chakraPetch(
                          fontSize: 11,
                          color: zc.textDim,
                          letterSpacing: 1,
                        ),
                      ),
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
