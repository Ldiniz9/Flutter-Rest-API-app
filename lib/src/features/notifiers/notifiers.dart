import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

class SavedRepositoriesNotifier extends StateNotifier<List<String>> {
  final SharedPreferences prefs;
  
  SavedRepositoriesNotifier(this.prefs) : super(
      prefs.getStringList('saved_repositories') ?? []
  );
  
  bool saveRepository(String url) {
    if (!state.contains(url)) {
      state = [...state, url];
      prefs.setStringList('saved_repositories', state);
      return true;
    }
    return false;
  }
  
  void removeRepository(int index) {
    final newList = [...state];
    newList.removeAt(index);
    state = newList;
    prefs.setStringList('saved_repositories', state);
  }
}

class VisualizationRequestNotifier extends StateNotifier<Map<String, AsyncValue<String?>>> {
  final Dio dio;
  
  VisualizationRequestNotifier(this.dio) : super({});
  
  Future<void> visualizationRequest(String url) async {
    if (!url.startsWith('https://api.github.com')) {
      url = 'https://api.github.com/${url.startsWith('/') ? url.substring(1) : url}';
    }
    
    state = {
      ...state,
      url: const AsyncValue.loading(),
    };
    
    try {
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'Authorization': 'adicionar aqui a chave de autorização do github',
          },
        ),
      );
      
      final prettyJson = const JsonEncoder.withIndent('  ').convert(response.data);
      state = {
        ...state,
        url: AsyncValue.data(prettyJson),
      };
    } on DioException catch (e) {
      state = {
        ...state,
        url: AsyncValue.error('Erro na requisição: ${e.message}', StackTrace.current),
      };
    }
  }
  
  void clearVisualization(String url) {
    final newState = Map<String, AsyncValue<String?>>.from(state);
    newState.remove(url);
    state = newState;
  }
  
  AsyncValue<String?> getState(String url) {
    return state[url] ?? const AsyncValue.data(null);
  }
}