import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Parent lock for the videos tab (Google Play Families policy: children use the
/// app, and videos come from YouTube / Instagram). Owner's choice, 2026-11-20.
///
/// The PIN is stored only as a salted SHA-256 hash on the device.
bool isValidPin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

String hashPin(String pin) => sha256.convert(utf8.encode('rattil.parentLock.$pin')).toString();

bool pinMatches(String pin, String? storedHash) => storedHash != null && hashPin(pin) == storedHash;

/// "Forgot the PIN?": a multiplication a young child can't easily answer (6..9 × 12..19).
(int, int) parentChallenge(Random r) => (6 + r.nextInt(4), 12 + r.nextInt(8));
