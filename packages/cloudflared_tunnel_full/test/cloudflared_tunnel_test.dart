import 'package:flutter_test/flutter_test.dart';
import 'package:cloudflared_tunnel_full/cloudflared_tunnel.dart';
import 'package:cloudflared_tunnel_full/cloudflared_tunnel_platform_interface.dart';
import 'package:cloudflared_tunnel_full/cloudflared_tunnel_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCloudflaredTunnelPlatform
    with MockPlatformInterfaceMixin
    implements CloudflaredTunnelPlatform {
  @override
  Future<String> getVersion() => Future.value('2024.1.1');

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
}
