import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../providers/gateway_provider.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _autoScroll = true;
  String _filter = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gateway Logs'),
        actions: [
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_top,
            ),
            tooltip: _autoScroll ? 'Auto-scroll on' : 'Auto-scroll off',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy all',
            onPressed: _copyAll,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Filter logs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _filter = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: Consumer<GatewayProvider>(
              builder: (context, provider, _) {
                final logs = provider.logs;
                final filtered = _filter.isEmpty
                    ? logs
                    : logs.where((l) => l.toLowerCase().contains(_filter)).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No logs yet'));
                }

                if (_autoScroll && _scrollController.hasClients) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final line = filtered[index];
                    final isError = line.toLowerCase().contains('error');
                    final isWarn = line.toLowerCase().contains('warn');
                    return SelectableText(
                      line,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: isError
                            ? theme.colorScheme.error
                            : isWarn
                                ? AppColors.statusAmber
                                : theme.colorScheme.onSurface,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _copyAll() {
    final provider = context.read<GatewayProvider>();
    final text = provider.logs.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All logs copied')),
    );
  }
}
