import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar : AppBar(
          title: Text('Platform View'),
        ),
        body: Center(
          child: WebView(),
        ),
      ),
    );
  }
}

typedef void WebViewCreatedCallback(WebViewController controller);

class WebView extends StatefulWidget {
  const WebView({
    Key key,
    this.onWebViewCreated,
  }) : super(key: key);

  final WebViewCreatedCallback onWebViewCreated;

  @override
  State<StatefulWidget> createState() => WebViewState();
}

class WebViewState extends State<WebView> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'webview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'webview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    // TODO add other platforms
    return Text(
        '$defaultTargetPlatform is not yet supported by the map view plugin');
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onWebViewCreated == null) {
      return;
    }
    widget.onWebViewCreated(new WebViewController(id));
  }
}

class WebViewController {
  WebViewController(int id) {
    this._channel = new MethodChannel('webview$id');
  }

  MethodChannel _channel;

  Future<void> loadUrl(String url) async {
    return _channel.invokeMethod('loadUrl', url);
  }
}


