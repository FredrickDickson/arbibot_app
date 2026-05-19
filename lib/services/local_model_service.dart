import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class LocalModelService {
  static const String _modelName = 'gemma-3n-it-q4_k_m.gguf';
  static const String _modelUrl = 'https://huggingface.co/google/gemma-3n-it-GGUF/resolve/main/gemma-3n-it-Q4_K_M.gguf';
  static const int _expectedSizeBytes = 2147483648; // ~2GB (estimated for Gemma 3n)

  String? _modelPath;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  final _progressController = StreamController<double>.broadcast();

  Stream<double> get downloadProgress => _progressController.stream;
  bool get isDownloading => _isDownloading;
  bool get isModelDownloaded => _modelPath != null && File(_modelPath!).existsSync();
  String? get modelPath => _modelPath;

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _modelPath = '${appDir.path}/$_modelName';
  }

  Future<void> downloadModel({void Function(double)? onProgress}) async {
    if (_isDownloading) return;
    if (isModelDownloaded) {
      onProgress?.call(1.0);
      return;
    }

    _isDownloading = true;
    _downloadProgress = 0.0;

    try {
      final response = await http.Client().send(http.Request('GET', Uri.parse(_modelUrl)));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download model: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? _expectedSizeBytes;
      final file = File(_modelPath!);
      final sink = file.openWrite();

      int downloadedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        _downloadProgress = downloadedBytes / contentLength;
        _progressController.add(_downloadProgress);
        onProgress?.call(_downloadProgress);
      }

      await sink.close();
      _isDownloading = false;
      _progressController.add(1.0);
      onProgress?.call(1.0);
    } catch (e) {
      _isDownloading = false;
      _progressController.addError(e);
      rethrow;
    }
  }

  Future<void> deleteModel() async {
    if (_modelPath != null && File(_modelPath!).existsSync()) {
      await File(_modelPath!).delete();
    }
  }

  Future<int> getModelSize() async {
    if (_modelPath == null) return 0;
    final file = File(_modelPath!);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  void dispose() {
    _progressController.close();
  }
}
