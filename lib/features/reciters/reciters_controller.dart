import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_service.dart';
import '../../data/local_store.dart';
import '../../data/models.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService(Dio()));

final recitersProvider =
    AsyncNotifierProvider<RecitersController, List<Reciter>>(
        RecitersController.new);

class RecitersController extends AsyncNotifier<List<Reciter>> {
  @override
  Future<List<Reciter>> build() => ref.watch(apiServiceProvider).getReciters();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(apiServiceProvider).getReciters());
  }
}

final reciterSearchQueryProvider = StateProvider<String>((ref) => '');

final favoritesProvider = NotifierProvider<FavoritesController, Set<int>>(
    FavoritesController.new);

class FavoritesController extends Notifier<Set<int>> {
  @override
  Set<int> build() => LocalStore.favoriteReciterIds.toSet();

  Future<void> toggle(int reciterId) async {
    await LocalStore.toggleFavoriteReciter(reciterId);
    final next = Set<int>.from(state);
    if (!next.remove(reciterId)) next.add(reciterId);
    state = next;
  }
}
