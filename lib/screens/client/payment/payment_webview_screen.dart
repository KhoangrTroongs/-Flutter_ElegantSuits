import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String title;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    this.title = 'Thanh toán',
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Cấu hình Controller cho WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            // Kiểm tra Deep Link "elegantsuits://" để xử lý kết quả thanh toán
            if (request.url.startsWith('elegantsuits://')) {
              _handleDeepLink(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  // Xử lý Deep Link trả về từ cổng thanh toán
  void _handleDeepLink(String url) {
    // Parse URL và lấy các tham số trạng thái
    final uri = Uri.parse(url);
    // Expected: elegantsuits://payment-result?orderId=123&status=success

    final status = uri.queryParameters['status'];
    // final orderId = uri.queryParameters['orderId']; // Optional usage

    // Đóng màn hình WebView và trả về kết quả
    if (mounted) {
      Navigator.of(context).pop({'status': status, 'fullUrl': url});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
