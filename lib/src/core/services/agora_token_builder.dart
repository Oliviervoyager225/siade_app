import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// ⚠️  DÉVELOPPEMENT UNIQUEMENT — ne jamais exposer le certificat en production.
const String _kAppCertificate = '169b45b62b6f4d1da3026a98dca26533';

// Agora privilege types
const _kPrivJoinChannel = 1;
const _kPrivPublishAudio = 2;
const _kPrivPublishVideo = 3;
const _kPrivPublishData = 4;

/// Génère un token Agora AccessToken2 (format "007").
/// Algorithme identique au package npm agora-token v2.0.3
/// (AccessToken2.build + ServiceRtc.pack).
///
/// Format : "007" + base64( zlib.deflate( putBytes(sig) + signingInfo ) )
/// — AVEC zlib ET SANS appId dans le préfixe du token —
///
/// [role] : 1 = broadcaster/publisher, 2 = audience/subscriber
String buildAgoraToken({
  required String appId,
  required String channelName,
  int uid = 0,
  int role = 2,
  int expireSeconds = 3600,
}) {
  // salt range: (1, 99999999) — identique au JS
  final salt = Random.secure().nextInt(99999999) + 1;
  final issueTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final expire = issueTs + expireSeconds; // timestamp absolu
  final uidStr = uid == 0 ? '' : uid.toString();

  // ── Privileges ────────────────────────────────────────────────────────────
  final privileges = <int, int>{_kPrivJoinChannel: expire};
  if (role == 1) {
    privileges[_kPrivPublishAudio] = expire;
    privileges[_kPrivPublishVideo] = expire;
    privileges[_kPrivPublishData] = expire;
  }

  // ── Service RTC pack : type + privileges + channelName + uid ─────────────
  // Miroir exact de ServiceRtc.pack() dans le npm :
  //   super.pack() = __pack_type() + __pack_privileges()
  //   puis buffer.pack() = putString(channelName) + putString(uid)
  final svc = _ByteBuf()
    ..putUint16(1) // serviceType = kRtcServiceType
    ..putTreeMapUint32(privileges)
    ..putString(channelName)
    ..putString(uidStr);

  // ── Signing info (servi à la fois pour la signature et le payload) ────────
  // Ordre : putString(appId) + issueTs + expire + salt + numServices + service
  final signingInfo = (_ByteBuf()
        ..putString(appId)
        ..putUint32(issueTs)
        ..putUint32(expire)
        ..putUint32(salt)
        ..putUint16(1) // 1 service
        ..putRaw(svc.bytes()))
      .bytes();

  // ── Signing key — 2 étapes HMAC séparées ─────────────────────────────────
  // Ordre EXACT du npm: encodeHMac(key, message)
  // step1 = HMAC-SHA256( key=uint32LE(issueTs), message=utf8(appCertificate) )
  final step1 = Hmac(sha256, (_ByteBuf()..putUint32(issueTs)).bytes())
      .convert(utf8.encode(_kAppCertificate))
      .bytes;
  // signingKey = HMAC-SHA256( key=uint32LE(salt), message=step1 )
  final signingKey = Hmac(sha256, (_ByteBuf()..putUint32(salt)).bytes())
      .convert(Uint8List.fromList(step1))
      .bytes;

  // ── Signature = HMAC-SHA256( key=signingKey, data=signingInfo ) ───────────
  final sig = Uint8List.fromList(
    Hmac(sha256, Uint8List.fromList(signingKey)).convert(signingInfo).bytes,
  );

  // ── Content = putBytes(sig) + signingInfo ─────────────────────────────────
  // putBytes = uint16LE(len) + bytes  (la signature a bien un préfixe longueur)
  final content = (_ByteBuf()
        ..putBytes(sig)
        ..putRaw(signingInfo))
      .bytes();

  // ── Zlib (deflate) + base64 ───────────────────────────────────────────────
  // Node.js zlib.deflateSync = format zlib RFC 1950 = dart:io ZLibEncoder
  final compressed = ZLibEncoder().convert(content);
  return '007${base64.encode(compressed)}';
}

// ─── ByteBuf little-endian (miroir exact du ByteBuf JS du package) ────────────

class _ByteBuf {
  final BytesBuilder _b = BytesBuilder();

  _ByteBuf putUint16(int v) {
    _b.addByte(v & 0xFF);
    _b.addByte((v >> 8) & 0xFF);
    return this;
  }

  _ByteBuf putUint32(int v) {
    _b.addByte(v & 0xFF);
    _b.addByte((v >> 8) & 0xFF);
    _b.addByte((v >> 16) & 0xFF);
    _b.addByte((v >> 24) & 0xFF);
    return this;
  }

  /// putBytes = uint16LE(len) + bytes (équivalent à putString pour une String)
  _ByteBuf putBytes(Uint8List bytes) {
    putUint16(bytes.length);
    _b.add(bytes);
    return this;
  }

  /// putString = putBytes(utf8(str))
  _ByteBuf putString(String s) => putBytes(Uint8List.fromList(utf8.encode(s)));

  /// putTreeMapUint32 = uint16(count) + [uint16(key) + uint32(value)]
  _ByteBuf putTreeMapUint32(Map<int, int> map) {
    putUint16(map.length);
    for (final e in map.entries) {
      putUint16(e.key);
      putUint32(e.value);
    }
    return this;
  }

  /// putRaw = append bytes without length prefix
  _ByteBuf putRaw(Uint8List bytes) {
    _b.add(bytes);
    return this;
  }

  Uint8List bytes() => _b.toBytes();
}

