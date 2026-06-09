import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TtsBridge {
  final FlutterTts _tts = FlutterTts();
  WebViewController? _controller;

  double _currentRate = 0.5;
  String _lastText = '';

  Future<void> init() async {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(_currentRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setCompletionHandler(() {
      _notifyWeb('end');
    });
    _tts.setErrorHandler((msg) {
      debugPrint('[TtsBridge] error: $msg');
      _notifyWeb('error');
    });
  }

  void setController(WebViewController controller) {
    _controller = controller;
  }

  void handleMessage(JavaScriptMessage jsMessage) async {
    try {
      final data = jsonDecode(jsMessage.message) as Map<String, dynamic>;
      final action = data['action'] as String;

      switch (action) {
        case 'speak':
          _lastText = data['text'] as String;
          await _tts.stop();
          await _tts.speak(_lastText);
          _notifyWeb('start');
          break;
        case 'stop':
          await _tts.stop();
          _notifyWeb('end');
          break;
        case 'pause':
          await _tts.pause();
          _notifyWeb('pause');
          break;
        case 'resume':
          await _tts.speak(_lastText);
          _notifyWeb('resume');
          break;
        case 'setRate':
          final webRate = (data['rate'] as num).toDouble();
          _currentRate = _webRateToTtsRate(webRate);
          await _tts.setSpeechRate(_currentRate);
          break;
        case 'setLanguage':
          final lang = data['lang'] as String;
          await _tts.setLanguage(lang);
          break;
      }
    } catch (e) {
      debugPrint('[TtsBridge] parse error: $e');
    }
  }

  // 웹 배속(1.0/1.2/1.5) → flutter_tts(0.0~1.0) 변환
  double _webRateToTtsRate(double webRate) {
    final map = {1.0: 0.5, 1.2: 0.6, 1.5: 0.7};
    return map[webRate] ?? 0.5;
  }

  void _notifyWeb(String eventType) {
    _controller?.runJavaScript('''
      (function() {
        var evt = window.__ttsPendingUtterance;
        if (!evt) return;
        if (evt.on$eventType) evt.on$eventType({ type: '$eventType' });
        if ('$eventType' === 'end' || '$eventType' === 'error') {
          window.__ttsSpeaking = false;
          window.__ttsPendingUtterance = null;
        }
      })();
    ''');
  }

  // WebView에 주입할 speechSynthesis polyfill JavaScript
  static const String polyfillJs = r'''
(function() {
  if (window.__ttsBridgeInstalled) return;
  window.__ttsBridgeInstalled = true;
  window.__ttsSpeaking = false;
  window.__ttsPendingUtterance = null;

  function SpeechSynthesisUtterance(text) {
    this.text = text || '';
    this.lang = 'ko-KR';
    this.rate = 1.0;
    this.pitch = 1.0;
    this.volume = 1.0;
    this.onstart = null;
    this.onend = null;
    this.onerror = null;
    this.onpause = null;
    this.onresume = null;
  }
  window.SpeechSynthesisUtterance = SpeechSynthesisUtterance;

  var _synthImpl = {
    get speaking() { return window.__ttsSpeaking; },
    get pending() { return window.__ttsPendingUtterance !== null; },
    get paused() { return false; },

    speak: function(utterance) {
      window.__ttsPendingUtterance = utterance;
      window.__ttsSpeaking = true;
      var self = this;
      // TtsChannel 미준비 시 최대 20회(2초) 재시도
      var attempts = 0;
      function trySend() {
        if (window.TtsChannel) {
          TtsChannel.postMessage(JSON.stringify({ action: 'setLanguage', lang: utterance.lang || 'ko-KR' }));
          TtsChannel.postMessage(JSON.stringify({ action: 'setRate', rate: utterance.rate || 1.0 }));
          TtsChannel.postMessage(JSON.stringify({ action: 'speak', text: utterance.text }));
        } else if (attempts < 20) {
          attempts++;
          setTimeout(trySend, 100);
        }
      }
      trySend();
    },

    stop: function() {
      window.__ttsSpeaking = false;
      if (window.__ttsPendingUtterance && window.__ttsPendingUtterance.onend) {
        window.__ttsPendingUtterance.onend({ type: 'end' });
      }
      window.__ttsPendingUtterance = null;
      if (window.TtsChannel) TtsChannel.postMessage(JSON.stringify({ action: 'stop' }));
    },

    pause: function() {
      if (window.__ttsSpeaking) {
        window.__ttsSpeaking = false;
        if (window.TtsChannel) TtsChannel.postMessage(JSON.stringify({ action: 'pause' }));
      }
    },

    resume: function() {
      if (window.__ttsPendingUtterance) {
        window.__ttsSpeaking = true;
        if (window.TtsChannel) TtsChannel.postMessage(JSON.stringify({ action: 'resume' }));
      }
    },

    getVoices: function() {
      return [{
        name: 'Korean TTS',
        lang: 'ko-KR',
        default: true,
        localService: true,
        voiceURI: 'native'
      }];
    },

    cancel: function() { this.stop(); },
    onvoiceschanged: null
  };

  // 기존 speechSynthesis를 강제로 덮어씀 (일부 WebView에서 속성이 이미 존재)
  try {
    Object.defineProperty(window, 'speechSynthesis', {
      get: function() { return _synthImpl; },
      configurable: true
    });
  } catch(e) {
    window.speechSynthesis = _synthImpl;
  }

  setTimeout(function() {
    if (_synthImpl.onvoiceschanged) _synthImpl.onvoiceschanged();
  }, 100);

  console.log('[TtsBridge] polyfill installed');
})();
''';

  Future<void> dispose() async {
    await _tts.stop();
  }
}
