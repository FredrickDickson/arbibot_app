import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'package:arbibot/core/app_export.dart';
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
  final String _conversationTopic = 'Arbitration Law Discussion';
  String? _overallConfidence;

  @override
  void initState() {
    super.initState();
    _loadMockConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMockConversation() {
    setState(() {
      _messages.addAll([
        {
          "id": 1,
          "isUser": true,
          "content":
              "What are the key provisions of the Alternative Dispute Resolution Act, 2010 (Act 798) regarding arbitration agreements?",
          "timestamp": DateTime.now().subtract(const Duration(minutes: 15)),
        },
        {
          "id": 2,
          "isUser": false,
          "content":
              "The Alternative Dispute Resolution Act, 2010 (Act 798) establishes comprehensive provisions for arbitration agreements in Ghana. Section 4 defines an arbitration agreement as a written agreement to submit present or future disputes to arbitration. The Act requires arbitration agreements to be in writing, which includes electronic communications under Section 4(2).",
          "timestamp": DateTime.now().subtract(const Duration(minutes: 14)),
          "confidence": "high",
          "citations": [
            {
              "source": "Alternative Dispute Resolution Act, 2010 (Act 798)",
              "section": "Section 4",
              "page": 12,
              "authority": "primary",
            },
            {
              "source": "Alternative Dispute Resolution Act, 2010 (Act 798)",
              "section": "Section 4(2)",
              "page": 13,
              "authority": "primary",
            },
          ],
        },
        {
          "id": 3,
          "isUser": true,
          "content":
              "Can you explain the requirements for enforcing foreign arbitral awards in Ghana?",
          "timestamp": DateTime.now().subtract(const Duration(minutes: 10)),
        },
        {
          "id": 4,
          "isUser": false,
          "content":
              "Foreign arbitral awards are enforceable in Ghana under the Alternative Dispute Resolution Act, 2010 (Act 798), which incorporates the New York Convention principles. Section 54 provides that a foreign arbitral award shall be recognized as binding and enforced subject to the provisions of the Act. The party seeking enforcement must submit the original award or certified copy, along with the arbitration agreement.",
          "timestamp": DateTime.now().subtract(const Duration(minutes: 9)),
          "confidence": "medium",
          "citations": [
            {
              "source": "Alternative Dispute Resolution Act, 2010 (Act 798)",
              "section": "Section 54",
              "page": 45,
              "authority": "primary",
            },
          ],
        },
      ]);
      _overallConfidence = 'high';
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    text.isEmpty
        ? null
        : () {
            setState(() {
              _messages.add({
                "id": _messages.length + 1,
                "isUser": true,
                "content": text,
                "timestamp": DateTime.now(),
              });
              _isTyping = true;
            });

            _messageController.clear();
            _scrollToBottom();

            Future.delayed(const Duration(seconds: 3), () {
              setState(() {
                _isTyping = false;
                final confidence = [
                  'high',
                  'medium',
                  'low',
                ][DateTime.now().second % 3];

                _messages.add({
                  "id": _messages.length + 1,
                  "isUser": false,
                  "content":
                      "Based on the Alternative Dispute Resolution Act, 2010 (Act 798), $text requires careful consideration of the statutory provisions and relevant case law. The legal framework provides specific guidance on this matter, which should be reviewed in conjunction with the applicable regulations.",
                  "timestamp": DateTime.now(),
                  "confidence": confidence,
                  "citations": [
                    {
                      "source":
                          "Alternative Dispute Resolution Act, 2010 (Act 798)",
                      "section": "Section ${10 + DateTime.now().second % 50}",
                      "page": 20 + DateTime.now().second % 30,
                      "authority": "primary",
                    },
                  ],
                });

                (confidence == 'medium' || confidence == 'low')
                    ? () {
                        _showDisclaimer = true;
                        _disclaimerConfidence = confidence;
                      }()
                    : null;

                _scrollToBottom();
              });
            });
          }();
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
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _messages.clear();
      _loadMockConversation();
    });
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
      body: Column(
        children: [
          ChatHeaderWidget(
            topic: _conversationTopic,
            overallConfidence: _overallConfidence,
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
    );
  }
}
