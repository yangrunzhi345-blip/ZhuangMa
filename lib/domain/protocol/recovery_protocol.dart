import 'dart:convert';

import 'package:crypto/crypto.dart';

class RecoveryProtocol {
  final List<String> steps;
  final String expectedOutputHash; // SHA-256 of the original payload
  final String originalPayload; // Base64-encoded original payload
  static const version = 1;

  RecoveryProtocol(this.steps, this.expectedOutputHash, this.originalPayload);

  factory RecoveryProtocol.create(List<String> steps, String original) {
    final originalBytes = utf8.encode(original);
    return RecoveryProtocol(
      List.unmodifiable(steps),
      sha256.convert(originalBytes).toString(),
      base64Encode(originalBytes),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'transformationSteps': steps,
    'expectedOutputHash': expectedOutputHash,
    'hashAlgorithm': 'sha256',
    'originalPayload': originalPayload,
  };

  factory RecoveryProtocol.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('version')) {
      throw const FormatException('missing recovery protocol version');
    }
    if (json['version'] != version) {
      throw const FormatException('unsupported recovery protocol version');
    }
    if (json['hashAlgorithm'] != 'sha256') {
      throw const FormatException('unsupported hash algorithm');
    }
    if (json['transformationSteps'] is! List) {
      throw const FormatException('missing transformation steps');
    }
    if (json['originalPayload'] is! String) {
      throw const FormatException('missing original payload');
    }
    if (json['expectedOutputHash'] is! String) {
      throw const FormatException('missing expected output hash');
    }
    try {
      base64Decode(json['originalPayload'] as String);
    } on Object {
      throw const FormatException('invalid recovery payload');
    }
    return RecoveryProtocol(
      (json['transformationSteps'] as List).cast<String>(),
      json['expectedOutputHash'] as String,
      json['originalPayload'] as String,
    );
  }

  String recover() {
    final List<int> bytes;
    try {
      bytes = base64Decode(originalPayload);
    } on Object {
      throw const FormatException('invalid recovery payload');
    }
    final value = utf8.decode(bytes);
    final actualHash = sha256.convert(bytes).toString();
    if (actualHash != expectedOutputHash) {
      throw const FormatException('recovery hash mismatch');
    }
    return value;
  }
}
