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
}
