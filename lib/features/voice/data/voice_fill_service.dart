import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/utils/voice_parser.dart';
import 'parsed_care_details.dart';

/// Thrown with a message that is safe to show to the user.
class VoiceFillException implements Exception {
  final String message;
  const VoiceFillException(this.message);

  @override
  String toString() => message;
}

/// Result of turning a transcript into care-card details.
class VoiceFillResult {
  final ParsedCareDetails details;

  /// True when the server couldn't be reached and the on-device parser was
  /// used instead. It only picks up the name, species, breed and personality.
  final bool usedOfflineParser;

  const VoiceFillResult(this.details, {this.usedOfflineParser = false});
}

/// Sends the spoken transcript (text only, never audio) to the Pet Care Cards
/// web app, which runs the same AI parser as the website's voice fill.
/// The AI key lives on that server; nothing secret ships in the app.
class VoiceFillService {
  static const endpoint = 'https://petcarecards.app/api/public/voice/parse';

  final Uri _uri;
  final Duration timeout;

  VoiceFillService({String url = endpoint, this.timeout = const Duration(seconds: 45)})
      : _uri = Uri.parse(url);

  Future<VoiceFillResult> parse(String transcript) async {
    final text = transcript.trim();
    if (text.length < 8) {
      throw const VoiceFillException(
        "We didn't hear enough. Try again, or type the details instead.",
      );
    }

    try {
      return VoiceFillResult(await _parseOnServer(text));
    } on VoiceFillException {
      rethrow;
    } catch (_) {
      // No connection, timeout or an unexpected reply: fall back to the
      // simple on-device parser so the user still gets something.
      final offline = offlineParse(text);
      if (offline.isEmpty) {
        throw const VoiceFillException(
          "We couldn't reach the voice service. Check your connection and try again.",
        );
      }
      return VoiceFillResult(offline, usedOfflineParser: true);
    }
  }

  Future<ParsedCareDetails> _parseOnServer(String transcript) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.postUrl(_uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set('x-pcc-client', 'mobile');
      request.add(utf8.encode(jsonEncode({'transcript': transcript})));
      final response = await request.close().timeout(timeout);
      final body = await response.transform(utf8.decoder).join().timeout(timeout);

      Object? json;
      try {
        json = jsonDecode(body);
      } catch (_) {
        json = null;
      }

      if (response.statusCode != 200) {
        final message = json is Map ? cleanString(json['error']) : null;
        // 4xx/429 carry a friendly message from the server: show it.
        // Anything else (5xx, HTML error page) falls back to offline parsing.
        if (message != null && response.statusCode < 500 && message.length < 180) {
          throw VoiceFillException(message);
        }
        throw HttpException('Voice service returned ${response.statusCode}');
      }
      if (json is! Map) throw const FormatException('Unexpected reply');
      return ParsedCareDetails.fromJson(json);
    } finally {
      client.close(force: true);
    }
  }

  /// The basic on-device parser, mapped onto the full details shape.
  static ParsedCareDetails offlineParse(String transcript) {
    final info = VoiceParser.parse(transcript);
    final details = ParsedCareDetails.empty();
    details.pet['name'] = info.name;
    details.pet['species'] = info.species;
    details.pet['breed'] = info.breed;
    details.pet['personality'] = info.personality;
    return details;
  }
}
