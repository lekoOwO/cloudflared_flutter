import 'package:flutter_test/flutter_test.dart';
import 'package:cloudflared_tunnel/cloudflared_tunnel.dart';
import 'package:cloudflared_tunnel/cloudflared_tunnel_platform_interface.dart';
import 'package:cloudflared_tunnel/cloudflared_tunnel_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCloudflaredTunnelPlatform
    with MockPlatformInterfaceMixin
    implements CloudflaredTunnelPlatform {
  Map<String, Object?>? lastStartArgs;

  @override
  Future<String> getVersion() => Future.value('2024.1.1');

  @override
  Future<void> start({
    required String token,
    required String originUrl,
    int haConnections = 4,
    bool enablePostQuantum = false,
    String quickTunnelUrl = '',
  }) async {
    lastStartArgs = {
      'token': token,
      'originUrl': originUrl,
      'haConnections': haConnections,
      'enablePostQuantum': enablePostQuantum,
      'quickTunnelUrl': quickTunnelUrl,
    };
  }

  @override
  Stream<TunnelEvent> get tunnelEventStream =>
      const Stream<TunnelEvent>.empty();

  @override
  Stream<ServerEvent> get serverEventStream =>
      const Stream<ServerEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final CloudflaredTunnelPlatform initialPlatform =
      CloudflaredTunnelPlatform.instance;

  test('$MethodChannelCloudflaredTunnel is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCloudflaredTunnel>());
  });

  test('getVersion', () async {
    final fakePlatform = MockCloudflaredTunnelPlatform();
    CloudflaredTunnelPlatform.instance = fakePlatform;
    final cloudflaredTunnelPlugin = CloudflaredTunnel();

    expect(await cloudflaredTunnelPlugin.getVersion(), '2024.1.1');
    cloudflaredTunnelPlugin.dispose();
  });

  test('startTunnel forwards quick tunnel options to platform start', () async {
    final fakePlatform = MockCloudflaredTunnelPlatform();
    CloudflaredTunnelPlatform.instance = fakePlatform;
    final cloudflaredTunnelPlugin = CloudflaredTunnel();

    await cloudflaredTunnelPlugin.startTunnel(
      token: 'test-token',
      originUrl: 'http://127.0.0.1:8080',
      quickTunnelUrl: 'random.trycloudflare.com',
      haConnections: 1,
      enablePostQuantum: true,
    );

    expect(fakePlatform.lastStartArgs, {
      'token': 'test-token',
      'originUrl': 'http://127.0.0.1:8080',
      'haConnections': 1,
      'enablePostQuantum': true,
      'quickTunnelUrl': 'random.trycloudflare.com',
    });
    cloudflaredTunnelPlugin.dispose();
  });
}
