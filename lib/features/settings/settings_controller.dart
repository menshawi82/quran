import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_store.dart';

enum AppThemeMode { system, light, dark }

enum AppStorageLocation { internal, external }

class SettingsState {
  const SettingsState({
    required this.offlineMode,
    required this.themeMode,
    required this.storageLocation,
  });

  final bool offlineMode;
  final AppThemeMode themeMode;
  final AppStorageLocation storageLocation;

  SettingsState copyWith({
    bool? offlineMode,
    AppThemeMode? themeMode,
    AppStorageLocation? storageLocation,
  }) =>
      SettingsState(
        offlineMode: offlineMode ?? this.offlineMode,
        themeMode: themeMode ?? this.themeMode,
        storageLocation: storageLocation ?? this.storageLocation,
      );
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final saved = LocalStore.themeMode;
    final themeMode = AppThemeMode.values.asNameMap()[saved] ?? AppThemeMode.system;
    final savedStorage = LocalStore.storageLocation;
    final storageLocation =
        AppStorageLocation.values.asNameMap()[savedStorage] ??
            AppStorageLocation.internal;
    return SettingsState(
      offlineMode: LocalStore.offlineMode,
      themeMode: themeMode,
      storageLocation: storageLocation,
    );
  }

  void setOfflineMode(bool value) {
    LocalStore.offlineMode = value;
    state = state.copyWith(offlineMode: value);
  }

  void setThemeMode(AppThemeMode mode) {
    LocalStore.themeMode = mode.name;
    state = state.copyWith(themeMode: mode);
  }

  void setStorageLocation(AppStorageLocation location) {
    LocalStore.storageLocation = location.name;
    state = state.copyWith(storageLocation: location);
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
