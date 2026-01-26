import "package:speech_to_text/speech_to_text.dart";

class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  bool get isAvailable => _available;

  Future<bool> init({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    _available = await _speech.initialize(
      onStatus: onStatus,
      onError: (error) => onError?.call(error.errorMsg),
    );
    return _available;
  }

  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!_available) return;
    await _speech.listen(
      onResult: (result) => onResult(
        result.recognizedWords,
        result.finalResult,
      ),
      listenFor: const Duration(seconds: 6),
      pauseFor: const Duration(seconds: 2),
      localeId: "pt_BR",
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }
}
