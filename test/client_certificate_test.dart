import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv/core/remote/drivers/androidtv/client_certificate.dart';

void main() {
  test('generates a cert + key that load into a SecurityContext', () {
    final cert = ClientCertificate.generate(keySize: 1024);

    expect(cert.certificatePem, contains('BEGIN CERTIFICATE'));
    expect(cert.privateKeyPem, contains('PRIVATE KEY'));
    // The real proof: BoringSSL accepts the PEM pair for client auth.
    expect(cert.securityContext, returnsNormally);
  });
}
