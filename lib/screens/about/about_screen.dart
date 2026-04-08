import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with SingleTickerProviderStateMixin {
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUpi() async {
    final upiUri = Uri.parse('upi://pay?pa=zenzero@slc&pn=Zenzer0s&tn=Kite Support&cu=INR');
    try {
      if (await canLaunchUrl(upiUri)) {
        await launchUrl(upiUri, mode: LaunchMode.externalApplication);
      } else {
        _showCopyDialog('UPI ID', 'zenzero@slc');
      }
    } catch (e) {
      _showCopyDialog('UPI ID', 'zenzero@slc');
    }
  }

  void _showCopyDialog(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'About',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 20),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  // Hero Section
                  const SizedBox(height: 10),
                  ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.04).animate(
                      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      width: 100, // Reduced from 120
                      height: 100, // Reduced from 120
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.surface,
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.1),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kite',
                    style: GoogleFonts.outfit(
                      fontSize: 28, // Reduced from 32
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    'Fly through your media downloads',
                    style: GoogleFonts.outfit(
                      fontSize: 14, // Reduced from 15
                      color: cs.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32), // Reduced from 40

                  // Solid Info Sections
                  _AboutSection(
                    cs: cs,
                    title: 'Developer',
                    children: [
                      _LinkTile(
                        cs: cs,
                        title: 'Zenzer0s',
                        subtitle: 'Visit GitHub profile',
                        icon: PhosphorIcons.githubLogo(),
                        onTap: () => _launchUrl('https://github.com/zenzer0s'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12), // Reduced from 16
                  
                  _AboutSection(
                    cs: cs,
                    title: 'Community',
                    children: [
                      _LinkTile(
                        cs: cs,
                        title: 'GitHub Repository',
                        subtitle: 'Open source code',
                        icon: PhosphorIcons.githubLogo(),
                        onTap: () => _launchUrl('https://github.com/zenzer0s/kite'),
                      ),
                      _LinkTile(
                        cs: cs,
                        title: 'Telegram Group',
                        subtitle: 'Get support & updates',
                        icon: PhosphorIcons.telegramLogo(),
                        onTap: () => _launchUrl('https://t.me/zen0saospforge'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32), // Reduced from 48

                  // Simplified Donation Row (ViVi Style)
                  Text(
                    'Support project development',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.outline,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SupportIcon(
                        cs: cs,
                        icon: Icons.account_balance_rounded,
                        label: 'UPI',
                        onTap: _launchUpi,
                      ),
                      const SizedBox(width: 48),
                      _SupportIcon(
                        cs: cs,
                        icon: Icons.coffee_rounded,
                        label: 'Coffee',
                        onTap: () => _launchUrl('https://buymeacoffee.com/zenzer0s'),
                      ),
                    ],
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Version 1.0.0 · Project Kite',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: cs.outline.withValues(alpha: 0.5),
                    letterSpacing: 0.8,
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

class _AboutSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final ColorScheme cs;

  const _AboutSection({
    required this.title,
    required this.children,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: cs.primary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _LinkTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: cs.secondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
            Icon(Icons.chevron_right_rounded, size: 18, color: cs.outlineVariant),
          ],
        ),
      ),
    );
  }
}

class _SupportIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _SupportIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          icon: Icon(icon, size: 22),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: cs.secondaryContainer.withValues(alpha: 0.5),
            foregroundColor: cs.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
