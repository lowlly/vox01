import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'tts_bridge.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  static const String _targetUrl = 'https://vox01.appstudy.co.kr/Study/index.asp?GenType=app';

  late final WebViewController _controller;
  final TtsBridge _ttsBridge = TtsBridge();
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // WebView 컨트롤러를 즉시 초기화 (build()가 바로 호출되므로 동기로 처리)
    _initWebView();
    // TTS 초기화는 백그라운드에서 비동기 진행
    _ttsBridge.init();
  }

  void _initWebView() {
    // 로컬 변수로 먼저 생성 — 콜백 클로저가 _controller 미할당 상태를 참조하지 않도록
    final controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'TtsChannel',
        onMessageReceived: _ttsBridge.handleMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          setState(() { _isLoading = true; _hasError = false; });
          controller.runJavaScript(TtsBridge.polyfillJs);
        },
        onPageFinished: (_) {
          setState(() => _isLoading = false);
          controller.runJavaScript(TtsBridge.polyfillJs);
        },
        onWebResourceError: (error) {
          debugPrint('[WebView] ${error.errorCode}: ${error.description}');
          if (error.isForMainFrame ?? true) {
            setState(() { _hasError = true; _isLoading = false; });
          }
        },
        onNavigationRequest: (request) {
          final uri = Uri.parse(request.url);
          if (uri.host.endsWith('appstudy.co.kr')) {
            return NavigationDecision.navigate;
          }
          launchUrl(uri, mode: LaunchMode.externalApplication);
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(_targetUrl));

    _controller = controller;
    _ttsBridge.setController(_controller);
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '인터넷 연결을 확인해주세요',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() { _hasError = false; _isLoading = true; });
              _controller.loadRequest(Uri.parse(_targetUrl));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ttsBridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: _hasError ? _buildErrorView() : Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1565C0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
