import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HttpPackageWebView extends StatefulWidget {
  @override
  _HttpPackageWebViewState createState() => _HttpPackageWebViewState();
}

class _HttpPackageWebViewState extends State<HttpPackageWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse(
          'https://www.dicomlibrary.com/meddream/?study=1.2.826.0.1.3680043.8.1055.1.20111102150758591.92402465.76095170',
        ), //https://www.dicomlibrary.com/meddream/?study=1.2.826.0.1.3680043.8.1055.1.20111102150758591.92402465.76095170
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        17,
        13,
        13,
      ), // optional if you want white icon contrast
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
            ),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}
