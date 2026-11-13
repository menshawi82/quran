import 'dart:async';

import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'local_store.dart';
import 'models.dart';

class OfflineException implements Exception {
  @override
  String toString() =>
      'وضع الأوفلاين مفعّل، والبيانات غير متوفرة محلياً بعد';
}

class NoNetworkException implements Exception {
  @override
  String toString() =>
      'لا يوجد اتصال بالإنترنت، اعرض ما تم تنزيله أو أوقف وضع الأوفلاين';
}

class ApiService {
  ApiService(this._dio);

  final Dio _dio;

  List<Reciter> _parse(Map<String, dynamic> json) =>
      ((json['reciters']) as List? ?? [])
          .map((e) => Reciter.fromJson(e as Map<String, dynamic>))
          .toList();

  List<RadioStation> _parseRadios(Map<String, dynamic> json) =>
      ((json['radios']) as List? ?? [])
          .map((e) => RadioStation.fromJson(e as Map<String, dynamic>))
          .where((r) => r.url.isNotEmpty && !r.name.trim().startsWith('ترجمة'))
          .toList();

  Future<List<Reciter>> getReciters() async {
    if (LocalStore.offlineMode) {
      final cached = LocalStore.recitersCache;
      if (cached != null) return _parse(cached);
      throw OfflineException();
    }
    try {
      final response = await _dio
          .get(ApiConstants.recitersUrl, queryParameters: {
        'language': ApiConstants.language,
      }).timeout(const Duration(seconds: 20));
      final json = response.data as Map<String, dynamic>;
      await LocalStore.saveRecitersCache(json);
      return _parse(json);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        final cached = LocalStore.recitersCache;
        if (cached != null) return _parse(cached);
        throw NoNetworkException();
      }
      rethrow;
    }
  }

  Future<List<RadioStation>> getRadios() async {
    if (LocalStore.offlineMode) {
      final cached = LocalStore.radiosCache;
      if (cached != null) return _parseRadios(cached);
      throw OfflineException();
    }
    try {
      final response = await _dio
          .get(ApiConstants.radiosUrl, queryParameters: {
        'language': ApiConstants.language,
      }).timeout(const Duration(seconds: 20));
      final json = response.data as Map<String, dynamic>;
      await LocalStore.saveRadiosCache(json);
      return _parseRadios(json);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        final cached = LocalStore.radiosCache;
        if (cached != null) return _parseRadios(cached);
        throw NoNetworkException();
      }
      rethrow;
    }
  }
}
