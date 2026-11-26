import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mulla_flutter/mulla_flutter.dart';
import 'package:mulla_flutter/testing.dart';

/// Demo mode uses a fake API; sandbox mode pays a real test session from your backend.
void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mulla checkout example',
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          extensions: const [
            MullaCheckoutTheme(
                borderRadius: BorderRadius.all(Radius.circular(14)))
          ],
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _sessionId = TextEditingController();
  final _token = TextEditingController();
  final _baseUrl = TextEditingController();
  String? _lastResult;

  @override
  void dispose() {
    _sessionId.dispose();
    _token.dispose();
    _baseUrl.dispose();
    super.dispose();
  }

  Future<void> _demo() async {
    final result = await showMullaCheckout(
      context,
      client: demoClient(),
      sessionId: 'cs_demo',
      token: 'tok_demo',
    );
    setState(() => _lastResult = '$result');
  }

  Future<void> _sandbox() async {
    final baseUrl = _baseUrl.text.trim();
    final client = MullaPublicClient(
      environment: Environment.test,
      baseUrl: baseUrl.isEmpty
          ? null
          : baseUrl, // e.g. http://10.0.2.2:3000/gateway for a local gateway
      appInfo: const AppInfo(name: 'mulla-flutter-example', version: '1.0.0'),
    );
    final result = await showMullaCheckout(
      context,
      client: client,
      sessionId: _sessionId.text.trim(),
      token: _token.text.trim(),
    );
    setState(() => _lastResult = '$result');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mulla checkout')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Demo (no account needed)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
                'Any MTN number works. The fake customer approves after 3 seconds; '
                'use an Airtel number to see a declined payment.'),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: _demo, child: const Text('Open demo checkout')),
            const Divider(height: 48),
            Text('Sandbox', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
                controller: _sessionId,
                decoration: const InputDecoration(labelText: 'Session id')),
            TextField(
                controller: _token,
                decoration: const InputDecoration(labelText: 'Session token')),
            TextField(
              controller: _baseUrl,
              decoration: const InputDecoration(
                  labelText: 'Base URL (optional)',
                  hintText: 'Official sandbox'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
                onPressed: _sandbox, child: const Text('Pay sandbox session')),
            if (_lastResult != null) ...[
              const SizedBox(height: 24),
              Text('Last result: $_lastResult'),
            ],
          ],
        ),
      );
}

/// A fake Mulla API: MTN numbers succeed after 3 s, Airtel numbers are declined.
MullaPublicClient demoClient() {
  final fake = FakeTransport();
  var status = 'PENDING';
  final events = StreamController<Map<String, Object?>>();

  Map<String, Object?> session() => {
        ...MullaFixtures.checkoutSession(
            id: 'cs_demo', amount: 12500, status: status),
        'reason': 'Order #1001 · 2 items',
        'merchant': {'name': 'Demo Coffee Shop'},
      };

  fake
    ..push((Request request) => Response(200, body: _json(session())))
    ..push((Request request) {
      final airtel = request.body!.contains('AIRTEL_RW');
      Timer(const Duration(seconds: 3), () {
        status = airtel ? 'FAILED' : 'SUCCESSFUL';
        events.add({
          'checkout': 'cs_demo',
          'status': status,
          'reference': 'CHG-TEST-1'
        });
      });

      return Response(200, body: _json(session()));
    })
    ..pushEventController(events);
  for (var i = 0; i < 20; i++) {
    fake.push((Request request) =>
        Response(200, body: _json(session()))); // refreshes on app resume
  }

  return MullaPublicClient(environment: Environment.test, transport: fake);
}

String _json(Map<String, Object?> data) => jsonEncode(data);
