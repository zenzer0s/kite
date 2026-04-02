import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/download_service.dart';

final ytdlpProvider = NotifierProvider<YtdlpNotifier, YtdlpState>(() {
  return YtdlpNotifier();
});

class YtdlpState {
  final String version;
  final bool isUpdating;
  final bool autoUpdate;
  final String? lastError;
  final String? lastStatus;

  const YtdlpState({
    required this.version,
    required this.isUpdating,
    required this.autoUpdate,
    this.lastError,
    this.lastStatus,
  });

  YtdlpState copyWith({
    String? version,
    bool? isUpdating,
    bool? autoUpdate,
    String? lastError,
    String? lastStatus,
  }) {
    return YtdlpState(
      version: version ?? this.version,
      isUpdating: isUpdating ?? this.isUpdating,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      lastError: lastError,
      lastStatus: lastStatus,
    );
  }
}

class YtdlpNotifier extends Notifier<YtdlpState> {
  static const _lastUpdateKey = 'ytdlp_last_update_time';
  static const _autoUpdateKey = 'ytdlp_auto_update';
  static const _updateIntervalMs = 7 * 24 * 60 * 60 * 1000;
  bool _started = false;

  @override
  YtdlpState build() {
    if (!_started) {
      _started = true;
      Future<void>.microtask(_init);
    }
    return const YtdlpState(
      version: 'Checking...',
      isUpdating: false,
      autoUpdate: true,
      lastStatus: null,
    );
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final autoUpdate = prefs.getBool(_autoUpdateKey) ?? true;
    state = state.copyWith(autoUpdate: autoUpdate);

    final version = await _readVersion();
    if (version != null) {
      state = state.copyWith(
        version: version,
        lastError: null,
        lastStatus: null,
      );
    }

    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final needsUpdate = now - lastUpdate > _updateIntervalMs;

    if ((autoUpdate && needsUpdate) || version == null) {
      await update();
    }
  }

  Future<void> toggleAutoUpdate(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoUpdateKey, value);
    state = state.copyWith(autoUpdate: value);
  }

  Future<String?> _readVersion() async {
    final version = await DownloadService.getYtDlpVersion();
    if (version.isEmpty || version == 'Unknown') {
      return null;
    }
    return version;
  }

  Future<void> fetchVersion() async {
    try {
      final version = await _readVersion();
      state = state.copyWith(
        version: version ?? 'Unknown',
        lastError: null,
        lastStatus: null,
      );
    } catch (e) {
      state = state.copyWith(
        version: 'Unknown',
        lastError: e.toString(),
        lastStatus: null,
      );
    }
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'DONE':
        return 'Updated';
      case 'ALREADY_UP_TO_DATE':
        return 'Up to date';
      default:
        return status;
    }
  }

  Future<void> _runUpdate() async {
    final status = await DownloadService.updateYtDlp();
    if (status != 'ERROR') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    }
    final version = await _readVersion();
    state = state.copyWith(
      version: version ?? 'Unknown',
      isUpdating: false,
      lastError: status == 'ERROR' ? status : null,
      lastStatus: status == 'ERROR' ? null : _mapStatus(status),
    );
  }

  Future<void> update() async {
    if (state.isUpdating) return;
    state = state.copyWith(isUpdating: true, lastError: null);
    try {
      await _runUpdate();
    } catch (e) {
      state = state.copyWith(isUpdating: false, lastError: e.toString());
    }
  }
}
