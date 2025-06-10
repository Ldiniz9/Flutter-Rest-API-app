import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../pages/repositories_screen.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});
  
  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends ConsumerState<InitialScreen> {
  final TextEditingController urlController = TextEditingController();
  String? currentUrl;
  
  @override
  Widget build(BuildContext context) {
    final visualizationState = ref.watch(visualizationRequestProvider);
    final currentState = currentUrl != null 
        ? visualizationState[currentUrl!] ?? const AsyncValue.data(null)
        : const AsyncValue.data(null);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Busca de Repositório Git'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.bookmark),
            label: const Text('Salvos'),
            onPressed: () {
              if (currentUrl != null) {
                ref.read(visualizationRequestProvider.notifier).clearVisualization(currentUrl!);
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedRepositoriesScreen()),
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
                    currentUrl = url;
                  });
                  
                  ref.read(visualizationRequestProvider.notifier).visualizationRequest(url);
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
                    currentUrl = url;
                  });
                  
                  ref.read(visualizationRequestProvider.notifier).visualizationRequest(url);
                },
                child: const Text('Buscar da API do GitHub'),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: currentState.when(
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
                            if (currentUrl != null) {
                              final success = ref.read(savedRepositoriesProvider.notifier)
                                  .saveRepository(currentUrl!);
                                
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
