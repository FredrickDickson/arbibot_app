import 'dart:async';
import 'dart:io' show Platform;
import 'local_model_service.dart';

// Conditional import for web compatibility
// flutter_llama doesn't support web, so we stub it out for web builds
import 'package:flutter_llama/flutter_llama.dart' if (dart.library.html) 'local_inference_stub.dart';

class LocalInferenceService {
  LocalModelService _modelService;
  dynamic _model;
  dynamic _session;
  bool _isInitialized = false;
  bool _isGenerating = false;

  LocalInferenceService(this._modelService);

  bool get isInitialized => _isInitialized;
  bool get isGenerating => _isGenerating;
  bool get isModelReady => _modelService.isModelDownloaded;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!_modelService.isModelDownloaded) {
      throw Exception('Model not downloaded. Call downloadModel() first.');
    }

    await _modelService.initialize();

    _model = await LlamaModel.loadFromFile(
      _modelService.modelPath!,
      params: LlamaParams(
        nCtx: 8192,
        nThreads: 4,
        nBatch: 512,
      ),
    );

    _session = await _model!.createSession();
    _isInitialized = true;
  }

  Stream<String> generateResponse({
    required String prompt,
    int maxTokens = 1024,
    double temperature = 0.7,
    double topP = 0.9,
  }) async* {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isGenerating) {
      throw Exception('Already generating a response');
    }

    _isGenerating = true;

    try {
      final systemPrompt = '''You are a helpful legal assistant specializing in arbitration and dispute resolution.
Provide accurate, professional legal information while being clear and concise.
Always consider the jurisdiction context when providing advice.''';

      final fullPrompt = '$systemPrompt\n\nUser: $prompt\nAssistant:';

      await _session!.prompt(fullPrompt);

      final controller = StreamController<String>();

      _session!.generate(
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
        onToken: (token) {
          controller.add(token);
        },
        onComplete: () {
          controller.close();
        },
      );

      await for (final token in controller.stream) {
        yield token;
      }
    } finally {
      _isGenerating = false;
    }
  }

  Future<String> generateResponseSync({
    required String prompt,
    int maxTokens = 1024,
    double temperature = 0.7,
    double topP = 0.9,
  }) async {
    final response = StringBuffer();
    await for (final token in generateResponse(
      prompt: prompt,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
    )) {
      response.write(token);
    }
    return response.toString();
  }

  void resetSession() {
    _session?.reset();
  }

  Future<void> dispose() async {
    await _session?.dispose();
    await _model?.dispose();
    _isInitialized = false;
  }
}
