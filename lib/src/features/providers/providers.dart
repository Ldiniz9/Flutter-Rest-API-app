import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/notifiers.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  return ref.watch(sharedPreferencesInitializerProvider).value!;
});

final sharedPreferencesInitializerProvider = FutureProvider<SharedPreferences>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs;
});

final savedRepositoriesProvider = StateNotifierProvider<SavedRepositoriesNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SavedRepositoriesNotifier(prefs);
});

final visualizationRequestProvider = StateNotifierProvider<VisualizationRequestNotifier, Map<String, AsyncValue<String?>>>((ref) {
  final dio = ref.watch(dioProvider);
  return VisualizationRequestNotifier(dio);
});