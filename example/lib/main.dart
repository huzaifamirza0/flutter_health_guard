import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_health_guard/flutter_health_guard.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // One line — collectors start before the UI.
  await Guardian.initialize();
  runApp(const GuardianExampleApp());
}

class GuardianExampleApp extends StatelessWidget {
  const GuardianExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Health Guard Example',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [Guardian.navigatorObserver],
      // Draggable shield FAB → in-app health report.
      builder: (context, child) => GuardianOverlay(
        visible: kDebugMode,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3ECF8E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _taps = 0;
  String _networkStatus = 'Idle';

  Future<void> _fetchSample() async {
    setState(() => _networkStatus = 'Loading…');
    try {
      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos/1'),
      );
      setState(() {
        _networkStatus =
            'HTTP ${response.statusCode} · ${response.bodyBytes.length} B';
      });
    } catch (e) {
      setState(() => _networkStatus = 'Error: $e');
    }
  }

  void _throwDemoError() {
    throw StateError('Demo error for Flutter Health Guard crash capture');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Health Guard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Just use the app',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '1. Drag the green shield anywhere\n'
            '2. Tap it to open the in-app report\n'
            '3. Tap Save to export files (one click)\n'
            '4. On Android/iOS, run guardian_bridge to sync into your PC project',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          GuardianWatch(
            name: 'CounterCard',
            child: Card(
              child: ListTile(
                title: const Text('Rebuild demo'),
                subtitle: Text('Taps: $_taps'),
                trailing: FilledButton(
                  onPressed: () => setState(() => _taps++),
                  child: const Text('Tap'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Network'),
            subtitle: Text(_networkStatus),
            trailing: FilledButton.tonal(
              onPressed: _fetchSample,
              child: const Text('GET'),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Navigation'),
            subtitle: const Text('Pushes a detail route (tracked by Guardian)'),
            trailing: FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _DetailPage(),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Crash demo'),
            subtitle: const Text('Captured in the report (debug only)'),
            trailing: FilledButton.tonal(
              onPressed: () {
                try {
                  _throwDemoError();
                } catch (e, st) {
                  FlutterError.reportError(
                    FlutterErrorDetails(exception: e, stack: st),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo error reported')),
                  );
                }
              },
              child: const Text('Throw'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPage extends StatelessWidget {
  const _DetailPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: const Center(
        child: Text('This route appears under Navigation in the report.'),
      ),
    );
  }
}
