// Stub implementation for web builds
// flutter_llama doesn't support web, so this provides dummy implementations

class LlamaParams {
  final int nCtx;
  final int nThreads;
  final int nBatch;

  LlamaParams({
    required this.nCtx,
    required this.nThreads,
    required this.nBatch,
  });
}

class LlamaModel {
  static Future<LlamaModel> loadFromFile(
    String path, {
    required LlamaParams params,
  }) async {
    throw UnimplementedError('Local inference is not supported on web');
  }

  Future<LlamaSession> createSession() async {
    throw UnimplementedError('Local inference is not supported on web');
  }

  Future<void> dispose() async {
    // No-op for web
  }
}

class LlamaSession {
  Future<void> prompt(String prompt) async {
    throw UnimplementedError('Local inference is not supported on web');
  }

  void generate({
    required int maxTokens,
    required double temperature,
    required double topP,
    required Function(String) onToken,
    required Function() onComplete,
  }) {
    throw UnimplementedError('Local inference is not supported on web');
  }

  void reset() {
    // No-op for web
  }

  Future<void> dispose() async {
    // No-op for web
  }
}
