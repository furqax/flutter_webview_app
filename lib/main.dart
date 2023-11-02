import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:dmgscooter/loading.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Permission.camera.request();
  // await Permission.microphone.request();
  // await Permission.storage.request();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);

    var swAvailable = await AndroidWebViewFeature.isFeatureSupported(
        AndroidWebViewFeature.SERVICE_WORKER_BASIC_USAGE);
    var swInterceptAvailable = await AndroidWebViewFeature.isFeatureSupported(
        AndroidWebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);

    if (swAvailable && swInterceptAvailable) {
      AndroidServiceWorkerController serviceWorkerController =
          AndroidServiceWorkerController.instance();

      await serviceWorkerController
          .setServiceWorkerClient(AndroidServiceWorkerClient(
        shouldInterceptRequest: (request) async {
          print(request);
          return null;
        },
      ));
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyWebView(),
    );
  }
}

class MyWebView extends StatefulWidget {
  const MyWebView({super.key});

  @override
  _MyWebViewState createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  InAppWebViewController? webViewController;

  bool isFirstTime = true;
  bool isLoading = true;

  Future<bool> _onWillPop() async {
    if (webViewController != null) {
      bool canGoBack = await webViewController!.canGoBack();
      if (canGoBack) {
        await webViewController!.goBack();
        return Future.value(false);
      }
    }
    return Future.value(true);
  }

  @override
  void initState() {
    super.initState();
    // Show splash screen for 3 seconds
    if (isFirstTime) {
      Timer(const Duration(seconds: 4), () {
        setState(() {
          isFirstTime = false;
        });
      });
    }
  }

  Future<void> _handleRefresh() async {
    if (webViewController != null) {
      webViewController!.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: InAppWebView(
                initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                    supportZoom: false,
                  ),
                ),
                initialUrlRequest: URLRequest(
                  url: Uri.parse("https://www.dmgscooterrentals.com/"),
                ),
                onLoadStop:
                    (InAppWebViewController controller, Uri? url) async {
                  await controller.evaluateJavascript(source: """
    var meta = document.createElement('meta');
    meta.name = 'viewport';
    meta.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
    var head = document.getElementsByTagName('head')[0];
    head.appendChild(meta);
  """);
                  setState(() {
                    isLoading = false;
                  });
                },
                onWebViewCreated: (InAppWebViewController controller) {
                  webViewController = controller;
                },
                onProgressChanged:
                    (InAppWebViewController controller, int progress) {
                  setState(() {
                    isLoading = true;
                  });
                },
              ),
            ),

            // Splash screen
            if (isFirstTime)
              Stack(
                children: [
                  // Full screen background image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/splashfood.jpg', // Replace with your background image
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Centered Logo
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 200,
                          ),
                          Image.asset(
                            'assets/logo.png', // Replace with your logo
                            width: 250,
                            height: 250,
                          )
                              .animate()
                              .scale(duration: 1000.ms)
                              .animate(
                                onComplete: (controller) => controller.repeat(),
                              )
                              .shimmer(duration: 3000.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // Loading screen
            if (isLoading && !isFirstTime)
              Container(
                color: Colors.white.withOpacity(0.5),
                child: const Center(
                  child: LoadingWidget(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
