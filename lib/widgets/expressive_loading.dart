import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpressiveLoadingIndicator extends StatelessWidget {
  const ExpressiveLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.android) {
      return const Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: AndroidView(
            viewType: 'com.zenzer0s.kite/expressive_loading',
            creationParamsCodec: StandardMessageCodec(),
          ),
        ),
      );
    }
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            strokeCap: StrokeCap.round,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
