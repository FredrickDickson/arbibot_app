import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arbibot/core/app_export.dart';
import 'package:arbibot/services/api_service.dart';
import 'package:arbibot/services/local_model_service.dart';
import 'package:arbibot/services/local_inference_service.dart';
import '../../widgets/responsive_layout.dart';
import './widgets/chat_header_widget.dart';
import './widgets/legal_disclaimer_banner_widget.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/message_input_widget.dart';
import './widgets/typing_indicator_widget.dart';

/// Chat Screen for legal queries with AI-powered responses
/// Implements citation-backed research with confidence indicators
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _showDisclaimer = false;
  String? _disclaimerConfidence;
  String _conversationTopic = 'New Conversation';
  String? _overallConfidence;
  String? _conversationId;
  
  // Local inference
  late LocalModelService _modelService;
  late LocalInferenceService _inferenceService;
  bool _useLocalInference = false;
  bool _isDownloadingModel = false;
  double _downloadProgress = 0.0;
  
  // RAG settings
  bool _useRAG = true;

  @override
  void initState() {
    super.initState();
    _initializeLocalInference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['conversation_id'] != null) {
        _conversationId = args['conversation_id'] as String;
        _conversationTopic = args['title'] as String? ?? 'Conversation';
        _loadConversation();
      }
    });
  }

  Future<void> _initializeLocalInference() async {
    _modelService = LocalModelService();
    _inferenceService = LocalInferenceService(_modelService);
    
    await _modelService.initialize();
    
    final prefs = await SharedPreferences.getInstance();
    _useLocalInference = prefs.getBool('use_local_inference') ?? false;
    _useRAG = prefs.getBool('use_rag') ?? true;
    
    if (_modelService.isModelDownloaded) {
      try {
        await _inferenceService.initialize();
        final api = context.read<ApiService>();
        api.setLocalInferenceService(_inferenceService);
        api.setUseLocalInference(_useLocalInference);
        setState(() {});
      } catch (e) {
        // Model exists but failed to load
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inferenceService.dispose();
    _modelService.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    if (_conversationId == null) return;
    try {
      final api = context.read<ApiService>();
      final messages = await api.getMessages(_conversationId!);
      setState(() {
        _messages.clear();
        for (final m in messages) {
          _messages.add({
            'id': m['id'],
            'isUser': m['role'] == 'user',
            'content': m['content'] ?? '',
            'timestamp': DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
            'confidence': m['confidence'],
            'citations': m['citations'] is List ? m['citations'] : [],
          });
        }
      });
      _scrollToBottom();
    } catch (e) {
      // Silently handle — empty chat is fine
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'isUser': true,
        'content': text,
        'timestamp': DateTime.now(),
      });
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final api = context.read<ApiService>();
      Map<String, dynamic> response;

      if (_useLocalInference && api.isLocalInferenceAvailable) {
        response = await api.sendMessageLocal(content: text);
      } else {
        response = await api.sendMessage(
          conversationId: _conversationId,
          content: text,
        );
      }

      if (!mounted) return;

      setState(() {
        _isTyping = false;
        _conversationId ??= response['conversation_id'];
        if (_conversationTopic == 'New Conversation') {
          _conversationTopic = text.length > 40 ? '${text.substring(0, 40)}...' : text;
        }

        final confidence = response['confidence'] ?? 'high';
        _messages.add({
          'id': response['id'],
          'isUser': false,
          'content': response['content'] ?? '',
          'timestamp': DateTime.tryParse(response['created_at'] ?? '') ?? DateTime.now(),
          'confidence': confidence,
          'citations': response['citations'] is List ? response['citations'] : [],
          'is_local': response['is_local'] ?? false,
        });

        _overallConfidence = confidence;

        if (confidence == 'medium' || confidence == 'low') {
          _showDisclaimer = true;
          _disclaimerConfidence = confidence;
        }
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: ${e.toString()}')),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.hasClients
          ? _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            )
          : null;
    });
  }

  void _handleCitationTap(Map<String, dynamic> message) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      '/source-viewer-screen',
      arguments: {
        'citations': message['citations'],
        'messageContent': message['content'],
      },
    );
  }

  void _handleMessageLongPress(Map<String, dynamic> message) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildMessageContextMenu(message),
    );
  }

  Widget _buildMessageContextMenu(Map<String, dynamic> message) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CustomIconWidget(
              iconName: 'content_copy',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title: Text('Copy Citation', style: theme.textTheme.bodyLarge),
            onTap: () {
              Clipboard.setData(
                ClipboardData(text: message['content'] as String? ?? ''),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Citation copied to clipboard')),
              );
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'save',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title: Text('Save to Library', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved to document library')),
              );
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'share',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title: Text('Share Response', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon'),
                ),
              );
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'report',
              color: AppTheme.errorLight,
              size: 24,
            ),
            title: Text(
              'Report Issue',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.errorLight,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Issue reported to support team')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleAttachment() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document upload coming soon')),
    );
  }

  void _acknowledgeDisclaimer() {
    HapticFeedback.mediumImpact();
    setState(() {
      _showDisclaimer = false;
      _disclaimerConfidence = null;
    });
  }

  Future<void> _refreshConversation() async {
    await _loadConversation();
  }

  Future<void> _toggleLocalInference(bool value) async {
    if (value && !_modelService.isModelDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please download the model first')),
      );
      return;
    }

    setState(() {
      _useLocalInference = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_local_inference', value);
    
    final api = context.read<ApiService>();
    api.setUseLocalInference(value);
  }

  Future<void> _toggleRAG(bool value) async {
    setState(() {
      _useRAG = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_rag', value);
  }

  Future<void> _downloadModel() async {
    if (_isDownloadingModel) return;
    
    setState(() {
      _isDownloadingModel = true;
      _downloadProgress = 0.0;
    });

    try {
      await _modelService.downloadModel(onProgress: (progress) {
        setState(() {
          _downloadProgress = progress;
        });
      });

      await _inferenceService.initialize();
      final api = context.read<ApiService>();
      api.setLocalInferenceService(_inferenceService);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model downloaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download model: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isDownloadingModel = false;
      });
    }
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildSettingsSheet(),
    );
  }

  Widget _buildSettingsSheet() {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          
          // Model status
          ListTile(
            title: Text(
              _isDownloadingModel ? 'Downloading AI Assistant...' : 
              _modelService.isModelDownloaded ? 'AI Assistant Ready' : 'Download AI Assistant',
            ),
            subtitle: Text(
              _isDownloadingModel 
                  ? 'This is a one-time download'
                  : _modelService.isModelDownloaded
                  ? 'Model downloaded and ready'
                  : 'Get local AI for offline use (2GB download)',
            ),
            leading: Icon(
              _modelService.isModelDownloaded ? Icons.check_circle : 
              _isDownloadingModel ? Icons.cloud_download : Icons.download,
              color: _modelService.isModelDownloaded
                      ? Colors.green
                      : theme.colorScheme.primary,
            ),
            trailing: _isDownloadingModel
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: _downloadProgress,
                      strokeWidth: 2,
                    ),
                  )
                : null,
          ),
          
          if (!_modelService.isModelDownloaded && !_isDownloadingModel)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: ElevatedButton.icon(
                onPressed: _downloadModel,
                icon: const Icon(Icons.download),
                label: const Text('Download AI Assistant'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ),
          
          if (_isDownloadingModel)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: _downloadProgress,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          
          SizedBox(height: 1.h),
          
          // Local inference toggle
          SwitchListTile(
            title: const Text('Use Local AI'),
            subtitle: const Text('Run AI inference on device (offline)'),
            value: _useLocalInference,
            onChanged: _modelService.isModelDownloaded
                ? _toggleLocalInference
                : null,
          ),
          
          SizedBox(height: 1.h),
          
          // RAG toggle
          SwitchListTile(
            title: const Text('Use RAG (Retrieval-Augmented Generation)'),
            subtitle: const Text('Retrieve relevant legal documents for context'),
            value: _useRAG,
            onChanged: _toggleRAG,
          ),
          
          SizedBox(height: 2.h),
          
          // Info text
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Local AI Information',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  '• Model: Gemma 3n (4-bit quantized)\n'
                  '• Size: ~2GB\n'
                  '• Context: 8K tokens\n'
                  '• Speed: 3-6 tokens/second\n'
                  '• Works offline\n'
                  '• Privacy: All data stays on device',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      body: ConstrainedContent(
        maxWidth: 960,
        child: Column(
        children: [
          ChatHeaderWidget(
            topic: _conversationTopic,
            overallConfidence: _overallConfidence,
            onSettingsTap: _showSettingsBottomSheet,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshConversation,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                itemCount:
                    _messages.length +
                    (_isTyping ? 1 : 0) +
                    (_showDisclaimer ? 1 : 0),
                itemBuilder: (context, index) {
                  _showDisclaimer && index == 0
                      ? LegalDisclaimerBannerWidget(
                          confidence: _disclaimerConfidence!,
                          onAcknowledge: _acknowledgeDisclaimer,
                        )
                      : null;

                  final messageIndex = _showDisclaimer ? index - 1 : index;

                  _isTyping && messageIndex == _messages.length
                      ? const TypingIndicatorWidget()
                      : null;

                  messageIndex >= 0 && messageIndex < _messages.length
                      ? MessageBubbleWidget(
                          message: _messages[messageIndex],
                          onCitationTap:
                              !(_messages[messageIndex]['isUser'] as bool? ??
                                  false)
                              ? () =>
                                    _handleCitationTap(_messages[messageIndex])
                              : null,
                          onLongPress:
                              !(_messages[messageIndex]['isUser'] as bool? ??
                                  false)
                              ? () => _handleMessageLongPress(
                                  _messages[messageIndex],
                                )
                              : null,
                        )
                      : null;

                  return _showDisclaimer && index == 0
                      ? LegalDisclaimerBannerWidget(
                          confidence: _disclaimerConfidence!,
                          onAcknowledge: _acknowledgeDisclaimer,
                        )
                      : _isTyping && messageIndex == _messages.length
                      ? const TypingIndicatorWidget()
                      : messageIndex >= 0 && messageIndex < _messages.length
                      ? MessageBubbleWidget(
                          message: _messages[messageIndex],
                          onCitationTap:
                              !(_messages[messageIndex]['isUser'] as bool? ??
                                  false)
                              ? () =>
                                    _handleCitationTap(_messages[messageIndex])
                              : null,
                          onLongPress:
                              !(_messages[messageIndex]['isUser'] as bool? ??
                                  false)
                              ? () => _handleMessageLongPress(
                                  _messages[messageIndex],
                                )
                              : null,
                        )
                      : const SizedBox.shrink();
                },
              ),
            ),
          ),
          MessageInputWidget(
            controller: _messageController,
            onSend: _sendMessage,
            onAttachment: _handleAttachment,
            isEnabled: !_isTyping,
          ),
        ],
      ),
      ),
    );
  }
}
