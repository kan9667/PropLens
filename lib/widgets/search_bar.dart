import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/voice_service.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController controller = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
            controller.text = text;
          });
        },
        onListeningStopped: () {
          setState(() {
            _isListening = false;
          });
          // Automatically search when listening stops and we have some text
          if (controller.text.trim().isNotEmpty) {
            provider.updateQuery(controller.text);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        //--------------------------------------------------
        // HERO BANNER & STARTUP BRANDING
        //--------------------------------------------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.blue.shade900, const Color(0xFF0F172A)]
                  : [Colors.blue.shade600, Colors.blue.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.home_work,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '360',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: '°',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withAlpha(230),
                          ),
                        ),
                        TextSpan(
                          text: ' Ghar',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withAlpha(220),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Find your dream home using AI',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withAlpha(220),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        //--------------------------------------------------
        // SEARCH INPUT PANEL
        //--------------------------------------------------
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? 'Listening...'
                            : 'Try: 2 BHK under 80 lakh with pool near DPS',
                        prefixIcon: const Icon(Icons.search, color: Colors.blue),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : Colors.blue,
                          ),
                          onPressed: () => _toggleListening(provider),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.blue.withAlpha(50),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (val) => provider.updateQuery(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        provider.updateQuery(controller.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Search',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}