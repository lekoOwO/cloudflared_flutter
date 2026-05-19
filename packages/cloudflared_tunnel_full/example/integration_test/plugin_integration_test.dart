// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:convert';
import 'dart:io';

import 'package:cloudflared_tunnel_full/cloudflared_tunnel_full.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getVersion test', (WidgetTester tester) async {
    final CloudflaredTunnel plugin = CloudflaredTunnel();
    final version = await plugin.getVersion();
    // The version string depends on the host platform running the test, so
    // just assert that some non-empty string is returned.
    expect(version.isNotEmpty, true);
  });

  testWidgets(
    'quick tunnel proxies public GET to local HTTP server',
    (WidgetTester tester) async {
      final shouldRun =
          Platform.environment['RUN_QUICK_TUNNEL_INTEGRATION'] == 'true';
      if (!shouldRun) {
        return;
      }

      final quickTunnel = await _createQuickTunnel();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requests = <Uri>[];
      final serverSub = server.listen((request) {
        requests.add(request.uri);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.text
          ..write('ok-from-local-server')
          ..close();
      });

      final plugin = CloudflaredTunnel();
      try {
        await plugin.startTunnel(
          token: quickTunnel.token,
          originUrl: 'http://127.0.0.1:${server.port}',
          quickTunnelUrl: quickTunnel.hostname,
          haConnections: 1,
        );

        final publicUrl = Uri.https(quickTunnel.hostname, '/pair/integration');
        final client = HttpClient();
        try {
          final response = await _eventuallyGetOk(client, publicUrl);
          expect(response.statusCode, HttpStatus.ok);
          expect(response.body, 'ok-from-local-server');
        } finally {
          client.close(force: true);
        }

        expect(requests.map((uri) => uri.path), contains('/pair/integration'));
      } finally {
        await plugin.stopTunnel();
        await serverSub.cancel();
        await server.close(force: true);
        plugin.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<_QuickTunnelCredentials> _createQuickTunnel() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client
        .postUrl(Uri.parse('https://api.trycloudflare.com/tunnel'))
        .timeout(const Duration(seconds: 15));
    request.headers.contentType = ContentType.json;
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'cloudflared-flutter-test',
    );
    final response = await request.close().timeout(const Duration(seconds: 15));
    final body = await utf8.decodeStream(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Quick tunnel request failed: HTTP ${response.statusCode}: $body',
      );
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final result = json['result'] as Map<String, dynamic>;
    final hostname = result['hostname'] as String;
    final secret = result['secret'];
    final secretBase64 =
        secret is String
            ? secret
            : base64Encode((secret as List<dynamic>).cast<int>());
    final tokenJson = <String, dynamic>{
      'a': result['account_tag'] as String,
      's': secretBase64,
      't': result['id'] as String,
    };
    final token = base64Encode(utf8.encode(jsonEncode(tokenJson)));
    return _QuickTunnelCredentials(token: token, hostname: hostname);
  } finally {
    client.close(force: true);
  }
}

Future<_HttpResult> _eventuallyGetOk(HttpClient client, Uri publicUrl) async {
  final deadline = DateTime.now().add(const Duration(seconds: 90));
  Object? lastError;

  while (DateTime.now().isBefore(deadline)) {
    try {
      final request = await client.getUrl(publicUrl);
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      if (response.statusCode == HttpStatus.ok) {
        return _HttpResult(response.statusCode, body);
      }
      lastError = 'HTTP ${response.statusCode}: $body';
    } catch (error) {
      lastError = error;
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  throw StateError(
    'Timed out waiting for $publicUrl to return 200: $lastError',
  );
}

class _QuickTunnelCredentials {
  final String token;
  final String hostname;

  _QuickTunnelCredentials({required this.token, required this.hostname});
}

class _HttpResult {
  final int statusCode;
  final String body;

  _HttpResult(this.statusCode, this.body);
}
