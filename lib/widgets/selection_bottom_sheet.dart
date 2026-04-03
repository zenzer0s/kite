import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomSheetOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const BottomSheetOption({
    required this.value,
    required this.label,
    this.icon,
  });
}

class SelectionBottomSheet<T> extends StatelessWidget {
  final String title;
  final T currentValue;
  final List<BottomSheetOption<T>> options;
  final ValueChanged<T> onSelected;
  final int itemsPerRow;

  const SelectionBottomSheet({
    super.key,
    required this.title,
    required this.currentValue,
    required this.options,
    required this.onSelected,
    this.itemsPerRow = 3,
  });

  static void show<T>(
    BuildContext context, {
    required String title,
    required T currentValue,
    required List<BottomSheetOption<T>> options,
    required ValueChanged<T> onSelected,
    int itemsPerRow = 3,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SelectionBottomSheet<T>(
          title: title,
          currentValue: currentValue,
          options: options,
          onSelected: onSelected,
          itemsPerRow: itemsPerRow,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <List<BottomSheetOption<T>>>[];
    for (var i = 0; i < options.length; i += itemsPerRow) {
      rows.add(
        options.sublist(
          i,
          i + itemsPerRow > options.length ? options.length : i + itemsPerRow,
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32.0, left: 16.0, right: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 16.0,
              ),
              child: Text(
                title,
                style: GoogleFonts.chakraPetch(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...rows.map(
              (rowOptions) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _SelectionRow<T>(
                  options: rowOptions,
                  currentValue: currentValue,
                  onSelected: (val) {
                    HapticFeedback.heavyImpact();
                    onSelected(val);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionRow<T> extends StatelessWidget {
  final List<BottomSheetOption<T>> options;
  final T currentValue;
  final ValueChanged<T> onSelected;

  const _SelectionRow({
    required this.options,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final optionValues = options.map((e) => e.value).toList();
    final isSelectedInRow = optionValues.contains(currentValue);

    return SegmentedButton<T>(
      emptySelectionAllowed: !isSelectedInRow,
      segments: options.map((opt) {
        return ButtonSegment<T>(
          value: opt.value,
          label: Text(
            opt.label,
            style: GoogleFonts.chakraPetch(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          icon: currentValue == opt.value
              ? const Icon(Icons.check_rounded, size: 18)
              : (opt.icon != null ? Icon(opt.icon, size: 18) : null),
        );
      }).toList(),
      selected: isSelectedInRow ? {currentValue} : <T>{},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) {
          onSelected(selected.first);
        }
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(context).colorScheme.primaryContainer;
          }
          return Theme.of(context).colorScheme.surfaceContainer;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(context).colorScheme.onPrimaryContainer;
          }
          return Theme.of(context).colorScheme.onSurface;
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
