import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdate {
  final String version;
  final String changelog;
  final String downloadUrl;
  final DateTime publishDate;
  final String commitSha;
  final String commitUrl;
  final bool isUpdateAvailable;

  AppUpdate({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
    required this.publishDate,
    required this.commitSha,
    required this.commitUrl,
    required this.isUpdateAvailable,
  });

  factory AppUpdate.empty() => AppUpdate(
        version: '0.0.0',
        changelog: '',
        downloadUrl: '',
        publishDate: DateTime.now(),
        commitSha: '',
        commitUrl: '',
        isUpdateAvailable: false,
      );
}

class UpdateState {
  final bool isLoading;
  final AppUpdate? update;
  final String? error;
  final String currentVersion;

  UpdateState({
    required this.isLoading,
    this.update,
    this.error,
    required this.currentVersion,
  });

  UpdateState copyWith({
    bool? isLoading,
    AppUpdate? update,
    String? error,
    String? currentVersion,
  }) {
    return UpdateState(
      isLoading: isLoading ?? this.isLoading,
      update: update ?? this.update,
      error: error ?? this.error,
      currentVersion: currentVersion ?? this.currentVersion,
    );
  }
}

final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(() {
  return UpdateNotifier();
});

class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() {
    _init();
    return UpdateState(isLoading: false, currentVersion: '1.0.0');
  }

  Future<void> _init() async {
    final info = await PackageInfo.fromPlatform();
    state = state.copyWith(currentVersion: info.version);
    // You could trigger an auto-check here if enabled in settings
  }

  Future<void> checkForUpdates() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/zenzer0s/kite/releases/latest'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');
        
        final isAvailable = _isVersionGreater(latestVersion, state.currentVersion);
        
        final commitSha = data['target_commitish'] ?? '';
        final update = AppUpdate(
          version: latestVersion,
          changelog: data['body'] ?? 'No changelog provided.',
          downloadUrl: data['html_url'] ?? '',
          publishDate: DateTime.parse(data['published_at']),
          commitSha: commitSha,
          commitUrl: commitSha.isNotEmpty 
              ? 'https://github.com/zenzer0s/kite/commit/$commitSha' 
              : 'https://github.com/zenzer0s/kite/commits',
          isUpdateAvailable: isAvailable,
        );

        state = state.copyWith(isLoading: false, update: update);
      } else {
        state = state.copyWith(
          isLoading: false, 
          error: 'Failed to fetch updates: ${response.statusCode}'
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network error or repository not found');
    }
  }

  bool _isVersionGreater(String latest, String current) {
    List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (var i = 0; i < latestParts.length && i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return latestParts.length > currentParts.length;
  }
}
