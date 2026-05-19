import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloudflared_tunnel_full/cloudflared_tunnel_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelCloudflaredTunnel();
  const channel = MethodChannel('com.cloudflare.cloudflared_tunnel/methods');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getVersion', () async {
    expect(await platform.getVersion(), '42');
  });

  test('start passes full quick tunnel options through the method channel',
      () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      capturedCall = methodCall;
      return null;
    });

    await platform.start(
      token: 'test-token',
      originUrl: 'http://127.0.0.1:3579',
      quickTunnelUrl: 'random.trycloudflare.com',
      haConnections: 1,
      enablePostQuantum: true,
    );

    expect(capturedCall?.method, 'start');
    expect(capturedCall?.arguments, <String, Object>{
      'token': 'test-token',
      'originUrl': 'http://127.0.0.1:3579',
      'haConnections': 1,
      'enablePostQuantum': true,
      'quickTunnelUrl': 'random.trycloudflare.com',
    });
  });
}
