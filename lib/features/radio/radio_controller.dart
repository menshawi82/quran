import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/local_store.dart';
import '../../data/models.dart';
import '../reciters/reciters_controller.dart';

const cairoStation = RadioStation(
  id: 0,
  name: 'إذاعة القرآن الكريم من القاهرة',
  url: ApiConstants.cairoRadioUrl,
);

const ruqyahStation = RadioStation(
  id: 114,
  name: 'الرقية الشرعية',
  url: ApiConstants.ruqyahRadioUrl,
);

final radiosProvider =
    AsyncNotifierProvider<RadiosController, List<RadioStation>>(
        RadiosController.new);

class RadiosController extends AsyncNotifier<List<RadioStation>> {
  @override
  Future<List<RadioStation>> build() async {
    return ref.watch(apiServiceProvider).getRadios();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(apiServiceProvider).getRadios());
  }
}

final radioSearchQueryProvider = StateProvider<String>((ref) => '');

final radioFavoritesProvider =
    NotifierProvider<RadioFavoritesController, Set<int>>(
        RadioFavoritesController.new);

class RadioFavoritesController extends Notifier<Set<int>> {
  @override
  Set<int> build() => LocalStore.favoriteRadioIds.toSet();

  Future<void> toggle(int radioId) async {
    await LocalStore.toggleFavoriteRadio(radioId);
    final next = Set<int>.from(state);
    if (!next.remove(radioId)) next.add(radioId);
    state = next;
  }
}

const _featuredOrder = [
  'العامة - متنوعة لمختلف القراء',
  'تلاوات خاشعة',
  'الرقية الشرعية',
  'سورة البقرة - لعدد من القراء',
  'تراتيل قصيرة متميزة',
  'آيات السكينة',
  'أذكار الصباح',
  'أذكار المساء',
  'إذاعة القرآن الكريم - السعودية',
  'صور من حياة الصحابة والتابعين',
  'المختصر في تفسير القرآن الكريم',
  'في ظلال السيرة النبوية',
  'المختصر في السيرة النبوية',
  'كتاب الاختيارات الفقهية',
  'تفسير القران الكريم-الخلاصة',
  'فضل شهر رمضان',
  'صحيح مسلم',
  'صحيح البخاري',
  'قصص الأنبياء',
  'رياض الصالحين',
  'تفسير غريب القرآن',
  'الشمائل المحمدية',
  'الفتاوى العامة',
  'تفسير القران الكريم',
  'تكبيرات العيد',
];

int? featuredIndex(RadioStation station) {
  final name = station.name.replaceAll(RegExp(r'[-*\s]'), '');
  for (var i = 0; i < _featuredOrder.length; i++) {
    if (name.startsWith(_featuredOrder[i].replaceAll(RegExp(r'[-*\s]'), ''))) {
      return i;
    }
  }
  return null;
}
