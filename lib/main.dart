import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

final dioProvider = Provider<Dio>((ref) => Dio());

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  return ref.watch(sharedPreferencesInitializerProvider).value!;
});

final sharedPreferencesInitializerProvider = FutureProvider<SharedPreferences>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs;
});


final repositoriosSalvosProvider = StateNotifierProvider<RepositoriosSalvosNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RepositoriosSalvosNotifier(prefs);
});

class RepositoriosSalvosNotifier extends StateNotifier<List<String>> {
  final SharedPreferences prefs;
  
  RepositoriosSalvosNotifier(this.prefs) : super(
      prefs.getStringList('repositorios_salvos') ?? []
  );
  
  bool salvarRepositorio(String url) {
    if (!state.contains(url)) {
      state = [...state, url];
      prefs.setStringList('repositorios_salvos', state);
      return true;
    }
    return false;
  }
  
  void removerRepositorio(int index) {
    final novaLista = [...state];
    novaLista.removeAt(index);
    state = novaLista;
    prefs.setStringList('repositorios_salvos', state);
  }
}

final visualizacaoRequestProvider = StateNotifierProvider<VisualizacaoRequestNotifier, Map<String, AsyncValue<String?>>>((ref) {
  final dio = ref.watch(dioProvider);
  return VisualizacaoRequestNotifier(dio);
});

class VisualizacaoRequestNotifier extends StateNotifier<Map<String, AsyncValue<String?>>> {
  final Dio dio;
  
  VisualizacaoRequestNotifier(this.dio) : super({});
  
  Future<void> fazerRequisicaoVisualizacao(String url) async {
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
  
  void limparVisualizacao(String url) {
    final newState = Map<String, AsyncValue<String?>>.from(state);
    newState.remove(url);
    state = newState;
  }
  
  AsyncValue<String?> getEstado(String url) {
    return state[url] ?? const AsyncValue.data(null);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends ConsumerStatefulWidget {
  const TelaInicial({super.key});
  
  @override
  _TelaInicialState createState() => _TelaInicialState();
}

class _TelaInicialState extends ConsumerState<TelaInicial> {
  final TextEditingController urlController = TextEditingController();
  String? urlAtual;
  
  @override
  Widget build(BuildContext context) {
    final visualizacaoState = ref.watch(visualizacaoRequestProvider);
    final estadoAtual = urlAtual != null 
        ? visualizacaoState[urlAtual!] ?? const AsyncValue.data(null)
        : const AsyncValue.data(null);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Busca de Repositório Git'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.bookmark),
            label: const Text('Salvos'),
            onPressed: () {
              if (urlAtual != null) {
                ref.read(visualizacaoRequestProvider.notifier).limparVisualizacao(urlAtual!);
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaRepositoriosSalvos()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'Coloque o link da API do GitHub',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixText: 'https://api.github.com/',
                ),
                onSubmitted: (value) {
                  String url = value;
                  if (!url.startsWith('https://api.github.com')) {
                    url = 'https://api.github.com/${url.startsWith('/') ? url.substring(1) : url}';
                  }
                  
                  setState(() {
                    urlAtual = url;
                  });
                  
                  ref.read(visualizacaoRequestProvider.notifier).fazerRequisicaoVisualizacao(url);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  String url = urlController.text;
                  if (!url.startsWith('https://api.github.com')) {
                    url = 'https://api.github.com/${url.startsWith('/') ? url.substring(1) : url}';
                  }
                  
                  setState(() {
                    urlAtual = url;
                  });
                  
                  ref.read(visualizacaoRequestProvider.notifier).fazerRequisicaoVisualizacao(url);
                },
                child: const Text('Buscar da API do GitHub'),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: estadoAtual.when(
                  data: (data) {
                    if (data == null) return const Center(child: Text(''));
                    
                    return Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: SingleChildScrollView(
                              child: Text(data),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (urlAtual != null) {
                              final success = ref.read(repositoriosSalvosProvider.notifier)
                                  .salvarRepositorio(urlAtual!);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(
                                    success 
                                      ? 'Repositório salvo com sucesso!' 
                                      : 'Este repositório já está salvo'
                                  )),
                                );
                            }
                          },
                          icon: const Icon(Icons.bookmark_add),
                          label: const Text('Salvar este repositório'),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(error.toString(), style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class TelaRepositoriosSalvos extends ConsumerStatefulWidget {
  const TelaRepositoriosSalvos({super.key});
  
  @override
  _TelaRepositoriosSalvosState createState() => _TelaRepositoriosSalvosState();
}

class _TelaRepositoriosSalvosState extends ConsumerState<TelaRepositoriosSalvos> {
  String? urlExpandida;
  
  @override
  Widget build(BuildContext context) {
    final repositorios = ref.watch(repositoriosSalvosProvider);
    
    return Scaffold(
      appBar: AppBar(
      title: const Text('Repositórios Salvos'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
        Navigator.pop(context);
          ref.read(visualizacaoRequestProvider.notifier).limparVisualizacao(urlExpandida!);
        },
      ),
      actions: [
        if (urlExpandida != null)
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
          setState(() {
            urlExpandida = null;
          });
          if (urlExpandida != null) {
            ref.read(visualizacaoRequestProvider.notifier).limparVisualizacao(urlExpandida!);
          }
          },
        ),
      ],
      ),
      body: repositorios.isEmpty
        ? const Center(child: Text('Nenhum repositório salvo ainda.'))
        : Column(
            children: [
              Expanded(
                flex: urlExpandida == null ? 1 : 0,
                child: ListView.builder(
                  shrinkWrap: urlExpandida != null,
                  physics: urlExpandida != null ? const NeverScrollableScrollPhysics() : null,
                  itemCount: repositorios.length,
                  itemBuilder: (context, index) {
                    final url = repositorios[index];
                    final isExpanded = urlExpandida == url;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      color: isExpanded ? Theme.of(context).primaryColor : null,
                      child: ListTile(
                        title: Text(
                          url,
                          style: TextStyle(
                            fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(isExpanded ? 'Visualizando dados...' : 'Toque para visualizar'),
                        leading: Icon(
                          Icons.code,
                          color: isExpanded ? Theme.of(context).primaryColor : null,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isExpanded ? Icons.visibility_off : Icons.visibility,
                                color: isExpanded ? Theme.of(context).primaryColor : Colors.blue,
                              ),
                              onPressed: () {
                                if (isExpanded) {
                                  setState(() {
                                    urlExpandida = null;
                                  });
                                  ref.read(visualizacaoRequestProvider.notifier).limparVisualizacao(url);
                                } else {
                                  setState(() {
                                    urlExpandida = url;
                                  });
                                  ref.read(visualizacaoRequestProvider.notifier).fazerRequisicaoVisualizacao(url);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                if (isExpanded) {
                                  setState(() {
                                    urlExpandida = null;
                                  });
                                }
                                ref.read(repositoriosSalvosProvider.notifier).removerRepositorio(index);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          if (isExpanded) {
                            setState(() {
                              urlExpandida = null;
                            });
                            ref.read(visualizacaoRequestProvider.notifier).limparVisualizacao(url);
                          } else {
                            setState(() {
                              urlExpandida = url;
                            });
                            ref.read(visualizacaoRequestProvider.notifier).fazerRequisicaoVisualizacao(url);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              
              if (urlExpandida != null) ...[
                const Divider(thickness: 2),
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Row(
                          children: [
                          const Icon(Icons.data_object, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                            'Dados: ${urlExpandida!}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            ),
                          ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Consumer(
                          builder: (context, ref, _) {
                            final estado = ref.watch(visualizacaoRequestProvider)[urlExpandida!] ?? 
                              const AsyncValue.loading();
                            
                            return estado.when(
                            data: (data) {
                              if (data == null) {
                              return const Center(child: Text('Carregando dados...'));
                              }
                              
                              return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.0),
                                color: Theme.of(context).cardColor,
                              ),
                              padding: const EdgeInsets.all(12.0),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                data,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                                ),
                              ),
                              );
                            },
                            loading: () => const Center(
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Carregando dados do repositório...'),
                              ],
                              ),
                            ),
                            error: (error, _) => Center(
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                'Erro ao carregar dados:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                error.toString(),
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                onPressed: () {
                                  ref.read(visualizacaoRequestProvider.notifier)
                                    .fazerRequisicaoVisualizacao(urlExpandida!);
                                },
                                child: const Text('Tentar novamente'),
                                ),
                              ],
                              ),
                            ),
                            );
                          },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
    );
  }
}
