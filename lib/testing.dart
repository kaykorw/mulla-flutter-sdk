/// Test helpers for apps using mulla_flutter: a public client backed by a [FakeTransport].
library;

import 'package:mulla_dart/mulla_dart.dart';
import 'package:mulla_dart/testing.dart';

export 'package:mulla_dart/mulla_dart.dart' show Request, Response;
export 'package:mulla_dart/testing.dart' show FakeTransport, MullaFixtures, WebhookSigner;

/// A [MullaPublicClient] that never touches the network.
(MullaPublicClient, FakeTransport) fakeMullaPublicClient({FakeTransport? transport}) {
  final fake = transport ?? FakeTransport();
  final client = MullaPublicClient(
    environment: Environment.test,
    transport: fake,
    sleep: (_) async {},
  );

  return (client, fake);
}
