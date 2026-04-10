import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

final aiServiceProvider = Provider((ref) => GeminiService());

class GeminiService {
  static const String _apiKey = 'AIzaSyC8cDbXvFSrLVQYFh4ImO2KOR7hJ34kxyo';
  static const List<String> _modelCandidates = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  late final List<GenerativeModel> _models;
  ChatSession? _chat;

  GeminiService() {
    _models = _modelCandidates
        .map(
          (modelName) => GenerativeModel(
            model: modelName,
            apiKey: _apiKey,
            generationConfig: GenerationConfig(
              temperature: 0.7,
              topK: 40,
              topP: 0.95,
              maxOutputTokens: 1024,
            ),
            systemInstruction: Content.system(
              'You are Kisan Saathi AI, a helpful and expert farming advisor for farmers in Andhra Pradesh. '
              'Respond in English by default. Only respond in Telugu when the user clearly writes in Telugu or explicitly asks for Telugu. '
              'If the user writes in English, always answer in English. Be concise, practical, and calm. '
              'Focus on crop health, pest control, irrigation, soil care, and weather-linked advice. '
              'If giving pesticide advice, include a brief safety note and suggest following local label instructions.',
            ),
          ),
        )
        .toList();

    if (_apiKey != 'YOUR_GEMINI_API_KEY') {
      _chat = _models.first.startChat();
    }
  }

  Future<String> sendMessage(String text, {List<XFile>? images}) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      return 'AI key not set. Add your Gemini API key in lib/services/ai_service.dart to enable chat.';
    }

    try {
      if (images != null && images.isNotEmpty) {
        return await _sendImageMessage(text, images);
      }
      return await _sendTextMessage(text);
    } catch (_) {
      return _offlineAdvice(text, hasImage: images != null && images.isNotEmpty);
    }
  }

  Future<String> _sendTextMessage(String text) async {
    Object? lastError;
    final prompt = _preparePrompt(text);

    for (final model in _models) {
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          _chat = model.startChat();
          final response = await _chat!.sendMessage(Content.text(prompt));
          final answer = response.text?.trim();
          if (answer != null && answer.isNotEmpty) {
            return answer;
          }
        } catch (error) {
          lastError = error;
          if (_isRetryable(error)) {
            await Future.delayed(Duration(seconds: attempt + 1));
            continue;
          }
          if (_isModelUnavailable(error)) {
            break;
          }
        }
      }
    }

    if (lastError != null && _isRetryable(lastError)) {
      return _offlineAdvice(text);
    }
    return _offlineAdvice(text);
  }

  Future<String> _sendImageMessage(String text, List<XFile> images) async {
    final imageParts = <DataPart>[];
    final prompt = _preparePrompt(text);
    for (final image in images) {
      final bytes = await image.readAsBytes();
      imageParts.add(DataPart('image/jpeg', bytes));
    }

    Object? lastError;
    for (final model in _models) {
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          final response = await model.generateContent([
            Content.multi([TextPart(prompt), ...imageParts]),
          ]);
          final answer = response.text?.trim();
          if (answer != null && answer.isNotEmpty) {
            return answer;
          }
        } catch (error) {
          lastError = error;
          if (_isRetryable(error)) {
            await Future.delayed(Duration(seconds: attempt + 1));
            continue;
          }
          if (_isModelUnavailable(error)) {
            break;
          }
        }
      }
    }

    if (lastError != null) {
      return _offlineAdvice(text, hasImage: true);
    }
    return _offlineAdvice(text, hasImage: true);
  }

  bool _isRetryable(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('503') ||
        message.contains('unavailable') ||
        message.contains('high demand') ||
        message.contains('deadline') ||
        message.contains('timeout') ||
        message.contains('connection');
  }

  bool _isModelUnavailable(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('404') ||
        message.contains('not found') ||
        message.contains('not supported for generatecontent');
  }

  String _preparePrompt(String text) {
    if (_containsTelugu(text)) {
      return 'Reply in Telugu.\n\n$text';
    }
    return 'Reply in English only.\n\n$text';
  }

  bool _containsTelugu(String text) {
    for (final rune in text.runes) {
      if (rune >= 0x0C00 && rune <= 0x0C7F) {
        return true;
      }
    }
    return false;
  }

  String _offlineAdvice(String text, {bool hasImage = false}) {
    final query = text.toLowerCase();

    if (hasImage) {
      return 'Image analysis service is busy right now. Please retry in a moment. Meanwhile, check for leaf spots, chewing damage, yellowing, stem rot, and pests under the leaf. Share a close, well-lit image for a better diagnosis.';
    }

    if (query.trim() == 'hi' ||
        query.trim() == 'hello' ||
        query.trim() == 'hey' ||
        query.contains('good morning') ||
        query.contains('good afternoon') ||
        query.contains('good evening')) {
      return 'Hello! I am Kisan Saathi AI. I can help you in English with crop diseases, pest control, fertilizer advice, irrigation tips, weather guidance, and market questions. Ask me anything about your farm.';
    }

    if (query.contains('worm') ||
        query.contains('caterpillar') ||
        query.contains('tomato')) {
      return 'Green worms on tomato are often fruit borers or caterpillars. Hand-pick visible worms, inspect leaves and fruits in the evening, remove damaged fruits, and use neem-based spray first. If infestation is heavy, use a label-approved caterpillar control product for tomato and follow local agricultural guidance.';
    }

    if (query.contains('fertilizer') || query.contains('groundnut')) {
      return 'For groundnut, use fertilizer based on soil test if possible. In general, farmers often focus on balanced nutrients with gypsum at the right stage for peg development. Avoid excess nitrogen, keep drainage good, and apply micronutrients only when deficiency is visible or recommended locally.';
    }

    if (query.contains('rain') ||
        query.contains('weather') ||
        query.contains('irrigation')) {
      return 'Check the weather card in the app before irrigation. If rain is likely within 24 to 48 hours, avoid overwatering. For dry conditions, use short irrigation intervals, mulching, and early morning watering to reduce moisture loss.';
    }

    if (query.contains('price') || query.contains('mandi') || query.contains('market')) {
      return 'For mandi prices, compare the latest market screen values with your nearest market before selling. If transport cost is high, wait for a better spread unless your crop quality may decline in storage.';
    }

    return 'The AI service is temporarily busy, but the app is still working. Please retry in a moment. If you want, ask a crop, pest, irrigation, fertilizer, or market question and I will give a practical fallback answer.';
  }
}
