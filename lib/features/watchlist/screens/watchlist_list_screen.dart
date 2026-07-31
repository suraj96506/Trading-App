import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/core/services/storage_service.dart';
import 'package:ticker_sim/core/models/watchlist.dart';
import 'package:ticker_sim/features/watchlist/providers/watchlist_provider.dart';
import 'watchlist_detail_screen.dart';

class WatchlistListScreen extends ConsumerWidget {
  const WatchlistListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistsAsync = ref.watch(watchlistsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlists')),
      body: watchlistsAsync.when(
        data: (watchlists) {
          if (watchlists.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Text(
                  'No watchlists yet.\nCreate one to start tracking stocks.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: watchlists.length,
            itemBuilder: (context, index) {
              final watchlist = watchlists[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.list),
                  title: Text(watchlist.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${watchlist.symbols.length} stock${watchlist.symbols.length != 1 ? 's' : ''}'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WatchlistDetailScreen(watchlist: watchlist),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final count = watchlistsAsync.value?.length ?? 0;
          final newList = Watchlist(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Watchlist ${count + 1}',
            symbols: [],
          );
          StorageService.instance.box<Watchlist>('watchlist').add(newList);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Watchlist'),
      ),
    );
  }
}
