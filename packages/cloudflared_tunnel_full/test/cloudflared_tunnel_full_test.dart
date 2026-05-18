import 'package:flutter_test/flutter_test.dart';
import 'package:cloudflared_tunnel_full/cloudflared_tunnel_full.dart';

void main() {
  test('cloudflared_tunnel_full entrypoint exports CloudflaredTunnel', () {
    expect(CloudflaredTunnel, isA<Type>());
  });
}
