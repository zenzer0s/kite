import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class FloatingNavToolbar extends StatelessWidget {
  final String currentRoute;
  final ScrollController? scrollController;
  final ValueChanged<String> onNavigate;
  final VoidCallback? onDownload;

  const FloatingNavToolbar({
    super.key,
    required this.currentRoute,
    this.scrollController,
    required this.onNavigate,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final containerColor = colorScheme.primaryContainer;
    final onContainerColor = colorScheme.onPrimaryContainer;
    final primaryColor = colorScheme.primary;
    final onPrimaryColor = colorScheme.onPrimary;

    // Optional toggle for displaying download action
    final showDownload = onDownload != null;

    final isAnyTabSelected = ['/queue', '/downloads'].contains(currentRoute);
    final spacing = isAnyTabSelected ? 1.0 : 8.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                _NavToolbarItem(
                  label: 'Queue',
                  icon: Icons.queue_rounded,
                  selected: currentRoute == '/queue',
                  primary: primaryColor,
                  onPrimary: onPrimaryColor,
                  onPrimaryContainer: onContainerColor,
                  onClick: () => onNavigate('/queue'),
                ),
                SizedBox(width: spacing),
                _NavToolbarItem(
                  label: 'Downloads',
                  icon: Icons.download_rounded,
                  selected: currentRoute == '/downloads',
                  primary: primaryColor,
                  onPrimary: onPrimaryColor,
                  onPrimaryContainer: onContainerColor,
                  onClick: () => onNavigate('/downloads'),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          if (showDownload) ...[
            const SizedBox(width: 8),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onDownload!();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: onPrimaryColor,
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.download_rounded, size: 24),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavToolbarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final Color onPrimary;
  final Color onPrimaryContainer;
  final VoidCallback onClick;

  const _NavToolbarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    // To properly mimic M3 expanding pill
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.fastOutSlowIn,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            onClick();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: selected ? 24.0 : 0.0, // 18 (icon) + 6 (spacing)
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    opacity: selected ? 1.0 : 0.0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 18, color: onPrimary),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.4,
                    color: selected ? onPrimary : onPrimaryContainer,
                  ),
                  child: Text(label, maxLines: 1, overflow: TextOverflow.clip),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
