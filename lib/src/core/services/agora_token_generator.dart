// ignore_for_file: constant_identifier_names
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Generates Agora AccessToken2 ("007" prefix) locally in Dart.
/// This avoids needing a Cloud Function for token generation.
///
/// Algorithm mirrors the official Agora SDK:
/// https://github.com/AgoraIO/Tools/tree/master/DynamicKey/AgoraDynamicKey
class AgoraTokenGenerator {
  static const _version = '007';
  static const _kServiceTypeRtc = 1;

  // RTC Privileges
  static const _kPrivJoinChannel = 1;
  static const _kPrivPublishAudio = 2;
  static const _kPrivPublishVideo = 3;
  static const _kPrivPublishData = 4;
  static const _kPrivSubscribeAudio = 7;
  static const _kPrivSubscribeVideo = 8;

  /// Génère un token Agora AccessToken2.
  ///
  /// [role] : 1 = broadcaster/publisher, 2 = audience/subscriber
  /// [uid]  : '' ou '0' pour let Agora assign automatically
  /// [expireSeconds] : validité du token en secondes (ex: 3600 = 1 heure)
  static String buildToken({
    required String appId,
    required String appCertificate,
    required String channelName,
    required String uid,
    required int role,
    int expireSeconds = 3600,
  }) {
    final salt = Random.secure().nextInt(0x7FFFFFFF) + 1;
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expireTs = ts + expireSeconds;

    final privileges = <int, int>{
      _kPrivJoinChannel: expireTs,
    };

    if (role == 1) {
      // broadcaster
      privileges[_kPrivPublishAudio] = expireTs;
      privileges[_kPrivPublishVideo] = expireTs;
      privileges[_kPrivPublishData] = expireTs;
    } else {
      // audience
      privileges[_kPrivSubscribeAudio] = expireTs;
      privileges[_kPrivSubscribeVideo] = expireTs;
    }

    // 1. Build signing content
    final sigContent = _packSigningContent(
        appId, salt, ts, expireTs, privileges, channelName, uid);

    // 2. HMAC-SHA256 signature
    final sig = Uint8List.fromList(
        Hmac(sha256, utf8.encode(appCertificate)).convert(sigContent).bytes);

    // 3. Build token message (signature + same fields, without appId)
    final tokenMsg = _packTokenMessage(
        sig, salt, ts, expireTs, privileges, channelName, uid);

    // 4. Zlib compress + standard base64
    final compressed = ZLibEncoder().convert(tokenMsg);

    return '$_version$appId${base64.encode(compressed)}';
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Uint8List _packSigningContent(
    String appId,
    int salt,
    int ts,
    int expire,
    Map<int, int> privileges,
    String channelName,
    String uid,
  ) {
    final p = _Packer();
    p.writeString(appId); // appId with length prefix
    p.writeUint32(salt);
    p.writeUint32(ts);
    p.writeUint32(expire);
    _writeRtcService(p, privileges, channelName, uid);
    return p.bytes();
  }

  static Uint8List _packTokenMessage(
    Uint8List signature,
    int salt,
    int ts,
    int expire,
    Map<int, int> privileges,
    String channelName,
    String uid,
  ) {
    final p = _Packer();
    p.writeBytes(signature); // signature with length prefix
    p.writeUint32(salt);
    p.writeUint32(ts);
    p.writeUint32(expire);
    _writeRtcService(p, privileges, channelName, uid);
    return p.bytes();
  }

  static void _writeRtcService(
    _Packer p,
    Map<int, int> privileges,
    String channelName,
    String uid,
  ) {
    p.writeUint16(1); // 1 service
    p.writeUint16(_kServiceTypeRtc);
    p.writeUint16(privileges.length);
    for (final e in privileges.entries) {
      p.writeUint16(e.key);
      p.writeUint32(e.value);
    }
    p.writeString(channelName);
    p.writeString(uid); // account (uid as string)
  }
}

/// Binary packer (little-endian), matching the C++ Packer in Agora's SDK.
class _Packer {
  final _b = BytesBuilder();

  void writeUint16(int v) {
    _b.addByte(v & 0xFF);
    _b.addByte((v >> 8) & 0xFF);
  }

  void writeUint32(int v) {
    _b.addByte(v & 0xFF);
    _b.addByte((v >> 8) & 0xFF);
    _b.addByte((v >> 16) & 0xFF);
    _b.addByte((v >> 24) & 0xFF);
  }

  void writeString(String s) {
    final bytes = utf8.encode(s);
    writeUint16(bytes.length);
    _b.add(bytes);
  }

  void writeBytes(Uint8List bytes) {
    writeUint16(bytes.length);
    _b.add(bytes);
  }

  Uint8List bytes() => _b.toBytes();
}
