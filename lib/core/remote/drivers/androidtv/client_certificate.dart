import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';

/// A self-signed RSA client certificate for the Android TV Remote mutual-TLS
/// handshake. Generated once and reused so the TV keeps trusting it after the
/// first pairing.
class ClientCertificate {
  const ClientCertificate({
    required this.certificatePem,
    required this.privateKeyPem,
  });

  final String certificatePem;
  final String privateKeyPem;

  /// Generates a fresh keypair and self-signed certificate.
  /// [keySize] is exposed so tests can use a faster 1024-bit key.
  static ClientCertificate generate({int keySize = 2048}) {
    final pair = CryptoUtils.generateRSAKeyPair(keySize: keySize);
    final privateKey = pair.privateKey as RSAPrivateKey;
    final publicKey = pair.publicKey as RSAPublicKey;

    final csr = X509Utils.generateRsaCsrPem(
      const {'CN': 'remote_tv'},
      privateKey,
      publicKey,
    );
    final certificatePem = X509Utils.generateSelfSignedCertificate(
      privateKey,
      csr,
      3650,
    );

    return ClientCertificate(
      certificatePem: certificatePem,
      privateKeyPem: CryptoUtils.encodeRSAPrivateKeyToPem(privateKey),
    );
  }

  /// A [SecurityContext] that presents this certificate for client auth.
  SecurityContext securityContext() =>
      SecurityContext(withTrustedRoots: false)
        ..useCertificateChainBytes(utf8.encode(certificatePem))
        ..usePrivateKeyBytes(utf8.encode(privateKeyPem));
}
