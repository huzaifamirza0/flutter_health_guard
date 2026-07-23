import 'package:flutter/material.dart';
import 'package:flutter_guardian/flutter_guardian.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  await Guardian.initialize(
    config: const GuardianConfig(
      enableLogs: true,
      enableNetwork: true,
      enablePerformance: true,
      enableNavigation: true,
      enableCrashes: true,
      outputDirectory: '.flutter_guardian',
      printCliSummary: true,
    ),
  );

  runApp(const GuardianExampleApp());
}

class GuardianExampleApp extends StatelessWidget {
  const GuardianExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Guardian',
      navigatorObservers: [Guardian.navigatorObserver],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3ECF8E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/details': (_) => const DetailsPage(),
      },
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
    Guardian.log('Fetching sample API', tag: 'demo');
    try {
      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos/1'),
      );
      setState(() {
        _networkStatus = 'HTTP ${response.statusCode} · ${response.bodyBytes.length} B';
      });
    } catch (e) {
      setState(() => _networkStatus = 'Error: $e');
    }
  }

  void _triggerError() {
    Guardian.log('About to throw a demo error', level: LogLevel.warning);
    throw StateError('Demo crash from Flutter Guardian example');
  }

  Future<void> _writeReport() async {
    final artifacts = await Guardian.generateReport(force: true);
    if (!mounted) return;
    final path = artifacts?.htmlPath ?? artifacts?.directory ?? 'unknown';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report written → $path')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Guardian')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Guardian Core v0.1',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap around, fire a network call, then generate a report. '
            'Open .flutter_guardian/report.html when you are done.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pushNamed('/details'),
            child: const Text('Open details route'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _triggerError,
            child: const Text('Throw demo error'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _writeReport,
            child: const Text('Generate Guardian report'),
          ),
        ],
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: const Center(
        child: Text('Navigation events are tracked automatically.'),
      ),
    );
  }
}
