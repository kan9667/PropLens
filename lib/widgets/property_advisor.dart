import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/voice_service.dart';

class PropertyAdvisorWidget extends StatefulWidget {
  const PropertyAdvisorWidget({super.key});

  @override
  State<PropertyAdvisorWidget> createState() => _PropertyAdvisorWidgetState();
}

class _PropertyAdvisorWidgetState extends State<PropertyAdvisorWidget> {
  final TextEditingController _controller = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;

  final List<String> _suggestions = [
    'Which property is best for a family?',
    'Which one is closest to schools?',
    'I need a property with good amenities.',
    'Which property gives the best value for money?',
    'Compare the top 3 options.',
  ];

  @override
  void dispose() {
    _voiceService.stopListening();
    _controller.dispose();
    super.dispose();
  }

  void _submitQuestion(AppProvider provider, String question) {
    if (question.trim().isEmpty) return;
    provider.askAdvisor(question);
    _controller.clear();
  }

  void _toggleListening(AppProvider provider) async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = true;
      });
      await _voiceService.startListening(
        onResult: (text) {
          setState(() {
            _controller.text = text;
          });
        },
        onListeningStopped: () {
          setState(() {
            _isListening = false;
          });
          if (_controller.text.trim().isNotEmpty) {
            _submitQuestion(provider, _controller.text);
          }
        },
        onError: (message) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.blue.withAlpha(38),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //--------------------------------------------------
          // PANEL HEADER
          //--------------------------------------------------
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Property Advisor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ask our conversational advisor to analyze and compare the top matched properties.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),

          //--------------------------------------------------
          // SUGGESTION CHIPS
          //--------------------------------------------------
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestions.map((suggestion) {
              return ActionChip(
                label: Text(
                  suggestion,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.blue.shade50.withAlpha(128),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.blue.withAlpha(25),
                  ),
                ),
                onPressed: provider.isAiLoading || _isListening
                    ? null
                    : () {
                        _submitQuestion(provider, suggestion);
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          //--------------------------------------------------
          // QUESTION TEXTFIELD & BUTTON
          //--------------------------------------------------
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !provider.isAiLoading,
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening...' : 'Ask about these properties...',
                    hintStyle: const TextStyle(fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.blue,
                      ),
                      onPressed: () => _toggleListening(provider),
                    ),
                  ),
                  onSubmitted: (val) => _submitQuestion(provider, val),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: provider.isAiLoading || _isListening
                      ? null
                      : () => _submitQuestion(provider, _controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: provider.isAiLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Ask AI',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),

          //--------------------------------------------------
          // AI ADVISOR RESPONSE PANEL
          //--------------------------------------------------
          if (provider.isAiLoading || provider.aiAnswer.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: provider.isAiLoading
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 12),
                        CircularProgressIndicator(strokeWidth: 3),
                        SizedBox(height: 16),
                        Text(
                          'Advisor is analyzing properties...',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 12),
                      ],
                    )
                  : SelectableText(
                      provider.aiAnswer,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        letterSpacing: 0.1,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
