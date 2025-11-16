import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:screen_protector/screen_protector.dart';

class YoutubePlayerWidget extends StatefulWidget {
  final String videoId;
  final String title;
  final bool autoPlay;
  final bool showControls;
  final double aspectRatio;

  const YoutubePlayerWidget({
    Key? key,
    required this.videoId,
    required this.title,
    this.autoPlay = false,
    this.showControls = true,
    this.aspectRatio = 16 / 9,
  }) : super(key: key);

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
    // Delay a frame to avoid ExpansionTile animation race conditions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWebView();
    });
  }

  Future<void> _enableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
    } catch (_) {}
  }

  void _initializeWebView() {
    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setBackgroundColor(const Color(0x00000000));
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          if (mounted) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          }
        },
        onPageFinished: (String url) async {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        onNavigationRequest: (NavigationRequest request) {
          // Allow YouTube and Google video domains, block others from breaking out
          final url = request.url;
          if (url.contains('youtube.com') ||
              url.contains('youtu.be') ||
              url.contains('googlevideo.com')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
        onWebResourceError: (WebResourceError error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
          _retryLoad();
        },
      ),
    );
    controller.loadHtmlString(_getEmbedHtml());

    _controller = controller;
    if (mounted) setState(() {});
  }

  String _getEmbedUrl() {
    final params = <String, String>{
      'autoplay': widget.autoPlay ? '1' : '0',
      'rel': '0',
      'modestbranding': '1',
      'controls': widget.showControls ? '1' : '0',
      'showinfo': '0',
      'iv_load_policy': '3',
      'cc_load_policy': '0',
      'fs': '0',
      'disablekb': '0',
      'playsinline': '1',
      'enablejsapi': '1',
      'origin': _retryCount >= _maxRetries - 1
          ? 'https://www.youtube.com'
          : 'https://www.youtube-nocookie.com',
      // Cache buster to avoid stale config state
      'cb': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final base = _retryCount >= _maxRetries - 1
        ? 'https://www.youtube.com'
        : 'https://www.youtube-nocookie.com';
    return '$base/embed/${widget.videoId}?$query';
  }

  String _getEmbedHtml() {
    final autoplay = widget.autoPlay ? '1' : '0';
    final controls = widget.showControls ? '1' : '0';
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    // Use standard youtube domain to reduce config errors on some devices
    final src =
        'https://www.youtube.com/embed/${widget.videoId}?autoplay=$autoplay&rel=0&modestbranding=1&controls=$controls&playsinline=1&iv_load_policy=3&enablejsapi=1&cb=$cacheBuster';
    final allow =
        'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen';
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
    <style>
      html, body { margin:0; padding:0; background: transparent; height: 100%; }
      .wrap { position: fixed; inset: 0; display: flex; align-items: center; justify-content: center; }
      .wrap iframe { width: 100%; height: 100%; border: 0; }
    </style>
  </head>
  <body>
    <div class="wrap">
      <iframe src="$src" allow="$allow" allowfullscreen></iframe>
    </div>
  </body>
  </html>
''';
  }

  Future<void> _retryLoad() async {
    if (_retryCount >= _maxRetries) return;
    _retryCount += 1;
    // small backoff
    await Future.delayed(Duration(milliseconds: 200 * _retryCount));
    if (!mounted) return;
    try {
      await _controller?.loadRequest(Uri.parse(_getEmbedUrl()));
      if (mounted) {
        setState(() {
          _hasError = false;
          _isLoading = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _disableScreenProtection();
    super.dispose();
  }

  Future<void> _disableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Check if videoId is valid
    if (widget.videoId.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'فيديو غير متوفر',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (_controller != null)
              AspectRatio(
                aspectRatio: widget.aspectRatio,
                child: WebViewWidget(controller: _controller!),
              )
            else
              Container(color: Colors.grey[200]),
            if (_isLoading)
              Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_hasError)
              Container(
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      const Text('خطأ في تحميل الفيديو',
                          style: TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _isLoading = true;
                            _retryCount = 0;
                          });
                          _initializeWebView();
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class YoutubePlayerFullscreen extends StatefulWidget {
  final String videoId;
  final String title;

  const YoutubePlayerFullscreen({
    Key? key,
    required this.videoId,
    required this.title,
  }) : super(key: key);

  @override
  State<YoutubePlayerFullscreen> createState() =>
      _YoutubePlayerFullscreenState();
}

class _YoutubePlayerFullscreenState extends State<YoutubePlayerFullscreen> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
    _initializeWebView();
  }

  Future<void> _enableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
    } catch (_) {}
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_getEmbedUrl()));
  }

  String _getEmbedUrl() {
    return 'https://www.youtube.com/embed/${widget.videoId}?autoplay=1&rel=0&modestbranding=1&controls=1&showinfo=0&iv_load_policy=3&cc_load_policy=0&fs=0&disablekb=0&playsinline=1&enablejsapi=1&origin=*';
  }

  @override
  void dispose() {
    _disableScreenProtection();
    super.dispose();
  }

  Future<void> _disableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: widget.videoId.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'فيديو غير متوفر',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            )
          : Center(
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
