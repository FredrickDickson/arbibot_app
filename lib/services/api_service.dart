import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_inference_service.dart';
import 'local_model_service.dart';

class ApiService {
  late final Dio _dio;
  final String baseUrl;
  LocalInferenceService? _localInference;
  bool _useLocalInference = false;

  ApiService({required this.baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          Supabase.instance.client.auth.refreshSession();
        }
        return handler.next(error);
      },
    ));
  }

  // ── Chat ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getConversations() async {
    final response = await _dio.get('/api/v1/chat/conversations');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final response = await _dio.get('/api/v1/chat/conversations/$conversationId/messages');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> sendMessage({
    String? conversationId,
    required String content,
    String jurisdiction = 'GH',
  }) async {
    final response = await _dio.post('/api/v1/chat/send', data: {
      'conversation_id': conversationId,
      'content': content,
      'jurisdiction': jurisdiction,
    });
    return Map<String, dynamic>.from(response.data);
  }

  Stream<String> sendMessageStream({
    String? conversationId,
    required String content,
    String jurisdiction = 'GH',
  }) async* {
    final session = Supabase.instance.client.auth.currentSession;
    final response = await _dio.post(
      '/api/v1/chat/send/stream',
      data: {
        'conversation_id': conversationId,
        'content': content,
        'jurisdiction': jurisdiction,
      },
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Accept': 'text/event-stream',
          if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
        },
      ),
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      while (buffer.contains('\n\n')) {
        final idx = buffer.indexOf('\n\n');
        final line = buffer.substring(0, idx).trim();
        buffer = buffer.substring(idx + 2);

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          try {
            final data = json.decode(jsonStr);
            if (data['done'] == true) {
              return;
            }
            if (data['content'] != null) {
              yield data['content'] as String;
            }
          } catch (_) {}
        }
      }
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    await _dio.delete('/api/v1/chat/conversations/$conversationId');
  }

  // ── Research ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> conductResearch({
    required String query,
    String jurisdiction = 'GH',
    List<String>? sourceTypes,
  }) async {
    final response = await _dio.post('/api/v1/research/', data: {
      'query': query,
      'jurisdiction': jurisdiction,
      if (sourceTypes != null) 'source_types': sourceTypes,
    });
    return Map<String, dynamic>.from(response.data);
  }

  // ── Drafts ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createDraft({
    required String documentType,
    required String title,
    String context = '',
    String jurisdiction = 'GH',
    String? conversationId,
  }) async {
    final response = await _dio.post('/api/v1/drafts/', data: {
      'document_type': documentType,
      'title': title,
      'context': context,
      'jurisdiction': jurisdiction,
      'conversation_id': conversationId,
    });
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getDrafts() async {
    final response = await _dio.get('/api/v1/drafts/');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getDraft(String draftId) async {
    final response = await _dio.get('/api/v1/drafts/$draftId');
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> approveDraft(String draftId, {required bool approved, String? reviewerNotes}) async {
    final response = await _dio.post('/api/v1/drafts/$draftId/approve', data: {
      'approved': approved,
      'reviewer_notes': reviewerNotes,
    });
    return Map<String, dynamic>.from(response.data);
  }

  // ── Cases ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCases() async {
    final response = await _dio.get('/api/v1/cases/');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createCase({
    required String caseTitle,
    String? caseNumber,
    Map<String, dynamic>? parties,
    String? arbitrationRules,
    String jurisdiction = 'GH',
  }) async {
    final response = await _dio.post('/api/v1/cases/', data: {
      'case_title': caseTitle,
      'case_number': caseNumber,
      'parties': parties ?? {},
      'arbitration_rules': arbitrationRules,
      'jurisdiction': jurisdiction,
    });
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> deleteCase(String caseId) async {
    await _dio.delete('/api/v1/cases/$caseId');
  }

  // ── Negotiation ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> createNegotiationAnalysis({
    required String disputeSummary,
    Map<String, dynamic>? partyPositions,
    String? caseId,
    String jurisdiction = 'GH',
  }) async {
    final response = await _dio.post('/api/v1/negotiation/analysis', data: {
      'dispute_summary': disputeSummary,
      'party_positions': partyPositions ?? {},
      'case_id': caseId,
      'jurisdiction': jurisdiction,
    });
    return Map<String, dynamic>.from(response.data);
  }

  // ── Procedural ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> generateTimeline(String caseId, {String? arbitrationRules}) async {
    final response = await _dio.post('/api/v1/procedural/timeline', data: {
      'case_id': caseId,
      'arbitration_rules': arbitrationRules,
    });
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> generateChecklist(String caseId) async {
    final response = await _dio.post('/api/v1/procedural/checklist', data: {
      'case_id': caseId,
    });
    return Map<String, dynamic>.from(response.data);
  }

  // ── Documents Library ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDocuments() async {
    final response = await _dio.get('/api/v1/documents/');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // ── Document Ingestion (RAG) ───────────────────────────────────────────

  Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String title,
    required String sourceType,
    String jurisdiction = 'GH',
    bool useOcr = false,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'title': title,
      'source_type': sourceType,
      'jurisdiction': jurisdiction,
      'use_ocr': useOcr,
    });

    final response = await _dio.post(
      '/api/v1/ingestion/upload',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> ingestText({
    required String text,
    required String title,
    required String sourceType,
    String jurisdiction = 'GH',
  }) async {
    final response = await _dio.post('/api/v1/ingestion/text', data: {
      'text': text,
      'title': title,
      'source_type': sourceType,
      'jurisdiction': jurisdiction,
    });
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getIngestionStats() async {
    final response = await _dio.get('/api/v1/ingestion/stats');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> deleteDocument(String sourceId) async {
    await _dio.delete('/api/v1/ingestion/$sourceId');
  }

  Future<Map<String, dynamic>> searchSimilarChunks({
    required String query,
    double matchThreshold = 0.75,
    int matchCount = 10,
    String? sourceType,
    String? jurisdiction,
  }) async {
    final response = await _dio.post('/api/v1/ingestion/search', data: {
      'query': query,
      'match_threshold': matchThreshold,
      'match_count': matchCount,
      if (sourceType != null) 'source_type': sourceType,
      if (jurisdiction != null) 'jurisdiction': jurisdiction,
    });
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> checkIngestionHealth() async {
    final response = await _dio.get('/api/v1/ingestion/health');
    return Map<String, dynamic>.from(response.data);
  }

  // ── Local Inference ───────────────────────────────────────────────

  void setLocalInferenceService(LocalInferenceService service) {
    _localInference = service;
  }

  void setUseLocalInference(bool useLocal) {
    _useLocalInference = useLocal;
  }

  bool get useLocalInference => _useLocalInference;
  bool get isLocalInferenceAvailable => _localInference?.isModelReady ?? false;

  Future<Map<String, dynamic>> sendMessageLocal({
    required String content,
    String jurisdiction = 'GH',
  }) async {
    if (_localInference == null || !_localInference!.isModelReady) {
      throw Exception('Local inference not available');
    }

    final response = await _localInference!.generateResponseSync(
      prompt: content,
      maxTokens: 1024,
      temperature: 0.7,
    );

    return {
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'content': response,
      'created_at': DateTime.now().toIso8601String(),
      'confidence': 'medium',
      'citations': [],
      'is_local': true,
    };
  }

  Stream<String> sendMessageStreamLocal({
    required String content,
    String jurisdiction = 'GH',
  }) async* {
    if (_localInference == null || !_localInference!.isModelReady) {
      throw Exception('Local inference not available');
    }

    yield* _localInference!.generateResponse(
      prompt: content,
      maxTokens: 1024,
      temperature: 0.7,
    );
  }
}
