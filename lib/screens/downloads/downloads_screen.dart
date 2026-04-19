import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/download_provider.dart';
import '../../services/download_service.dart';
import '../../widgets/queue_task_card.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tasks = ref.watch(downloadsProvider);
    final historyAsync = ref.watch(downloadHistoryProvider);

    final running = tasks.values
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.paused,
        )
        .toList();
    final queued = tasks.values
        .where((t) => t.status == DownloadStatus.queued)
        .toList();
    final cancelled = tasks.values
        .where((t) => t.status == DownloadStatus.cancelled)
        .toList();
    final errored = tasks.values
        .where((t) => t.status == DownloadStatus.error)
        .toList();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Download Queue',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert, color: cs.onSurface),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xFFFF8A8A), // Pinkish from screenshot
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: const Color(0xFFFF8A8A),
            unselectedLabelColor: cs.outline,
            labelStyle: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Running'),
              Tab(text: 'In Queue'),
              Tab(text: 'Cancelled'),
              Tab(text: 'Errored'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TaskList(
              tasks: running,
              emptyLabel: 'No running downloads',
              onClear: null,
            ),
            _TaskList(
              tasks: queued,
              emptyLabel: 'Queue is empty',
              onClear: null,
            ),
            _TaskList(
              tasks: cancelled,
              emptyLabel: 'No cancelled tasks',
              onClear: () =>
                  ref.read(downloadsProvider.notifier).clearCancelled(),
            ),
            _TaskList(
              tasks: errored,
              emptyLabel: 'No errored tasks',
              onClear: () =>
                  ref.read(downloadsProvider.notifier).clearErrored(),
            ),
            historyAsync.when(
              data: (items) => _HistoryList(items: items, cs: cs),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading history: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  final List<DownloadTask> tasks;
  final String emptyLabel;
  final VoidCallback? onClear;

  const _TaskList({
    required this.tasks,
    required this.emptyLabel,
    this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (onClear != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return QueueTaskCard(
                task: task,
                onCancel: () => ref
                    .read(downloadsProvider.notifier)
                    .cancelTask(task.taskId),
                onPause: () =>
                    ref.read(downloadsProvider.notifier).pauseTask(task.taskId),
                onResume: () => ref
                    .read(downloadsProvider.notifier)
                    .resumeTask(task.taskId),
                onDismiss: () => ref
                    .read(downloadsProvider.notifier)
                    .dismissTask(task.taskId),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryList extends ConsumerWidget {
  final List<DownloadedItem> items;
  final ColorScheme cs;

  const _HistoryList({required this.items, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No history yet',
          style: GoogleFonts.outfit(color: cs.outline),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return QueueTaskCard(
          task: DownloadTask(
            taskId: 'history_${item.id}',
            status: DownloadStatus.done,
            info: VideoInfo(
              id: item.id.toString(),
              title: item.title,
              uploader: item.uploader,
              thumbnail: item.thumbnail,
              duration: item.duration,
              url: item.url,
              ext: item.ext,
            ),
            progress: 100,
            filePath: item.filePath,
            quality: item.quality,
          ),
          onCancel: () {},
          onDismiss: () => ref.read(databaseProvider).deleteDownload(item.id),
        );
      },
    );
  }
}
