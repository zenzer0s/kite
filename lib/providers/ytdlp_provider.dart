import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/download_service.dart';

enum YtdlpChannel { stable, nightly, master }

enum YtdlpUpdateInterval { off, daily, weekly, monthly }

extension YtdlpIntervalExtension on YtdlpUpdateInterval {
  Duration? get duration {
    switch (this) {
      case YtdlpUpdateInterval.daily:
        return const Duration(days: 1);
      case YtdlpUpdateInterval.weekly:
        return const Duration(days: 7);
      case YtdlpUpdateInterval.monthly:
        return const Duration(days: 30);
      case YtdlpUpdateInterval.off:
        return null;
    }
  }
}

final ytdlpProvider = NotifierProvider<YtdlpNotifier, YtdlpState>(() {
  return YtdlpNotifier();
});

class YtdlpState {
  final String version;
  final bool isUpdating;
  final bool autoUpdate;
  final YtdlpChannel channel;
  final YtdlpUpdateInterval interval;
  final DateTime? lastUpdateTime;
  final String? lastError;
  final String? lastStatus;

  const YtdlpState({
    required this.version,
    required this.isUpdating,
    required this.autoUpdate,
    required this.channel,
    required this.interval,
    this.lastUpdateTime,
    this.lastError,
    this.lastStatus,
  });

  YtdlpState copyWith({
    String? version,
    bool? isUpdating,
    bool? autoUpdate,
    YtdlpChannel? channel,
    YtdlpUpdateInterval? interval,
    DateTime? lastUpdateTime,
    String? lastError,
    String? lastStatus,
  }) {
    return YtdlpState(
      version: version ?? this.version,
      isUpdating: isUpdating ?? this.isUpdating,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      channel: channel ?? this.channel,
      interval: interval ?? this.interval,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      lastError: lastError, // Reset on every copy unless explicitly provided
      lastStatus: lastStatus,
    );
  }
}

class YtdlpNotifier extends Notifier<YtdlpState> {
  static const _channelKey = 'ytdlp_update_channel';
  static const _intervalKey = 'ytdlp_auto_update_interval';
  static const _autoUpdateKey = 'ytdlp_auto_update';
  
  bool _initialized = false;

  @override
  YtdlpState build() {
    if (!_initialized) {
      _initialized = true;
      Future<void>.microtask(_init);
    }
    return const YtdlpState(
      version: 'Checking...',
      isUpdating: false,
      autoUpdate: true,
      channel: YtdlpChannel.stable,
      interval: YtdlpUpdateInterval.weekly,
      lastStatus: null,
    );
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    
    final autoUpdate = prefs.getBool(_autoUpdateKey) ?? true;
    final channelIndex = prefs.getInt(_channelKey) ?? 0;
    final intervalIndex = prefs.getInt(_intervalKey) ?? 2; // Default to weekly

    final lastUpdateMillis = await DownloadService.getYtDlpLastUpdateTime();
    final lastUpdateTime = lastUpdateMillis > 0 
        ? DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis) 
        : null;

    state = state.copyWith(
      autoUpdate: autoUpdate,
      channel: YtdlpChannel.values[channelIndex],
      interval: YtdlpUpdateInterval.values[intervalIndex],
      lastUpdateTime: lastUpdateTime,
    );

    final version = await _readVersion();
    if (version != null) {
      state = state.copyWith(version: version);
    }

    // Check for auto update
    if (autoUpdate && version != null) {
      final intervalDuration = state.interval.duration;
      if (intervalDuration != null && lastUpdateTime != null) {
        final nextUpdateTime = lastUpdateTime.add(intervalDuration);
        if (DateTime.now().isAfter(nextUpdateTime)) {
          await update();
        }
      } else if (lastUpdateTime == null) {
        // First run or manual reset
        await update();
      }
    } else if (version == null) {
      // Missing engine, force update
      await update();
    }
  }

  Future<void> setChannel(YtdlpChannel channel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_channelKey, channel.index);
    state = state.copyWith(channel: channel);
  }

  Future<void> setInterval(YtdlpUpdateInterval interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_intervalKey, interval.index);
    state = state.copyWith(interval: interval, autoUpdate: interval != YtdlpUpdateInterval.off);
    await prefs.setBool(_autoUpdateKey, interval != YtdlpUpdateInterval.off);
  }

  Future<String?> _readVersion() async {
    final version = await DownloadService.getYtDlpVersion();
    if (version.isEmpty || version == 'Unknown') {
      return null;
    }
    return version;
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'DONE':
        return 'Successfully Updated';
      case 'ALREADY_UP_TO_DATE':
        return 'Engine is up to date';
      default:
        return status;
    }
  }

  Future<void> update() async {
    if (state.isUpdating) return;
    state = state.copyWith(isUpdating: true, lastError: null, lastStatus: 'Checking for updates...');
    
    try {
      final status = await DownloadService.updateYtDlp(channel: state.channel.name);
      final version = await _readVersion();
      final lastUpdateMillis = await DownloadService.getYtDlpLastUpdateTime();
      
      state = state.copyWith(
        version: version ?? 'Unknown',
        isUpdating: false,
        lastUpdateTime: DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis),
        lastStatus: _mapStatus(status),
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false, 
        lastError: e.toString(),
        lastStatus: 'Update failed',
      );
    }
  }
}
