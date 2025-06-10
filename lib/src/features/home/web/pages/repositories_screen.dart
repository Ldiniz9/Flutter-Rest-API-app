import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';

class SavedRepositoriesScreen extends ConsumerStatefulWidget {
  const SavedRepositoriesScreen({super.key});
  
  @override
  _SavedRepositoriesScreenState createState() => _SavedRepositoriesScreenState();
}

class _SavedRepositoriesScreenState extends ConsumerState<SavedRepositoriesScreen> {
  String? expandedUrl;
  
  @override
  Widget build(BuildContext context) {
    final repositories = ref.watch(savedRepositoriesProvider);
    
    return Scaffold(
      appBar: AppBar(
      title: const Text('Repositórios Salvos'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
        Navigator.pop(context);
          ref.read(visualizationRequestProvider.notifier).clearVisualization(expandedUrl!);
        },
      ),
      actions: [
        if (expandedUrl != null)
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
          setState(() {
            expandedUrl = null;
          });
          if (expandedUrl != null) {
            ref.read(visualizationRequestProvider.notifier).clearVisualization(expandedUrl!);
          }
          },
        ),
      ],
      ),
      body: repositories.isEmpty
        ? const Center(child: Text('Nenhum repositório salvo ainda.'))
        : Column(
            children: [
              Expanded(
                flex: expandedUrl == null ? 1 : 0,
                child: ListView.builder(
                  shrinkWrap: expandedUrl != null,
                  physics: expandedUrl != null ? const NeverScrollableScrollPhysics() : null,
                  itemCount: repositories.length,
                  itemBuilder: (context, index) {
                    final url = repositories[index];
                    final isExpanded = expandedUrl == url;
                    
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
                                    expandedUrl = null;
                                  });
                                  ref.read(visualizationRequestProvider.notifier).clearVisualization(url);
                                } else {
                                  setState(() {
                                    expandedUrl = url;
                                  });
                                  ref.read(visualizationRequestProvider.notifier).visualizationRequest(url);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                if (isExpanded) {
                                  setState(() {
                                    expandedUrl = null;
                                  });
                                }
                                ref.read(savedRepositoriesProvider.notifier).removeRepository(index);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          if (isExpanded) {
                            setState(() {
                              expandedUrl = null;
                            });
                            ref.read(visualizationRequestProvider.notifier).clearVisualization(url);
                          } else {
                            setState(() {
                              expandedUrl = url;
                            });
                            ref.read(visualizationRequestProvider.notifier).visualizationRequest(url);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              
              if (expandedUrl != null) ...[
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
                            'Dados: ${expandedUrl!}',
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
                            final state = ref.watch(visualizationRequestProvider)[expandedUrl!] ?? 
                              const AsyncValue.loading();
                            
                            return state.when(
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
                                  ref.read(visualizationRequestProvider.notifier)
                                    .visualizationRequest(expandedUrl!);
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
