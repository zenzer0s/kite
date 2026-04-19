import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/download_provider.dart';
import '../services/download_service.dart';

class QueueTaskCard extends StatefulWidget {
  final DownloadTask task;
  final VoidCallback onCancel;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onDismiss;

  const QueueTaskCard({
    super.key,
    required this.task,
    required this.onCancel,
    this.onPause,
    this.onResume,
    this.onDismiss,
  });

  @override
  State<QueueTaskCard> createState() => _QueueTaskCardState();
}

class _QueueTaskCardState extends State<QueueTaskCard> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(QueueTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task != widget.task) {
      _channel?.invokeMethod('updateParams', _buildParams());
    }
  }

  Map<String, dynamic> _buildParams() {
    final task = widget.task;
    final isDone = task.status == DownloadStatus.done;
    final isError = task.status == DownloadStatus.error;
    final isCancelled = task.status == DownloadStatus.cancelled;
    final isQueued = task.status == DownloadStatus.queued;
    
    final fileExists = task.filePath != null && File(task.filePath!).existsSync();
    final isCleaned = !fileExists && task.nativeUploaded;

    final speed = _extractSpeed(task.currentLine);
    final qualityLabel = task.status == DownloadStatus.error ? 'Failed' : (task.quality ?? (task.targetExt == 'mp3' ? 'Best Audio' : 'Best Video'));
    
    double? progressValue = (task.status == DownloadStatus.downloading || task.status == DownloadStatus.paused) 
        ? task.progress / 100.0 
        : (task.status == DownloadStatus.fetching || task.status == DownloadStatus.queued ? null : 0.0);

    return {
      'type': 'queue_task_card',
      'title': task.info.title,
      'uploader': task.info.uploader,
      'thumbnail': task.info.thumbnail,
      'progress': progressValue,
      'speed': speed,
      'status': task.status.name,
      'targetExt': task.targetExt,
      'quality': qualityLabel,
      'isCleaned': isCleaned,
      'isDone': isDone,
      'isCancelled': isCancelled,
      'isError': isError,
      'isQueued': isQueued,
    };
  }

  String _extractSpeed(String? currentLine) {
    if (currentLine == null) return '0 KB/s';
    final match = RegExp(r'(\d+\.?\d*)\s*([KM]i?B/s)').firstMatch(currentLine);
    if (match != null) return '${match.group(1)} ${match.group(2)}';
    return '0 KB/s';
  }

  @override
  Widget build(BuildContext context) {
    // Return a box constraint to avoid infinite size exception
    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 16),
      child: AndroidView(
        key: ValueKey('queue_card_${widget.task.taskId}'),
        viewType: 'com.zenzer0s.kite/expressive_element',
        creationParams: _buildParams(),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          _channel = MethodChannel('com.zenzer0s.kite/expressive_$id');
          _channel?.setMethodCallHandler((call) async {
            if (call.method == 'onAction') {
              final action = call.arguments as String;
              if (action == 'show_telegram') {
                final cs = Theme.of(context).colorScheme;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          PhosphorIcons.telegramLogo(PhosphorIconsStyle.fill),
                          color: cs.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Available on Telegram',
                          style: GoogleFonts.outfit(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: cs.surfaceContainerHighest,
                    behavior: SnackBarBehavior.floating,
                    width: 240,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else if (action == 'open_file') {
                if (widget.task.filePath != null) {
                  DownloadService.openFile(widget.task.filePath!);
                }
              } else if (action == 'dismiss') {
                widget.onDismiss?.call();
              } else if (action == 'cancel') {
                widget.onCancel.call();
              }
            }
          });
        },
      ),
    );
  }
}
