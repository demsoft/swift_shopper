import 'dart:io';

import 'package:flutter/foundation.dart';

class AppEnv {
  const AppEnv._();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://footballapi.goserp.co.uk',
  );

  static const String _androidApiBaseUrl = String.fromEnvironment(
    'ANDROID_API_BASE_URL',
    defaultValue: '',
  );

  static const String customerId = String.fromEnvironment(
    'CUSTOMER_ID',
    defaultValue: 'customer-demo',
  );

  static const String orderId = String.fromEnvironment(
    'ORDER_ID',
    defaultValue: 'ORD-9001',
  );

  static String get apiBaseUrl {
    if (!kIsWeb && Platform.isAndroid && _androidApiBaseUrl.trim().isNotEmpty) {
      return _androidApiBaseUrl.trim();
    }

    return _baseUrl;
  }

  static String? get androidFallbackApiBaseUrl {
    if (kIsWeb || !Platform.isAndroid) {
      return null;
    }

    if (_baseUrl.contains('localhost')) {
      return _baseUrl.replaceFirst('localhost', '10.0.2.2');
    }

    if (_baseUrl.contains('10.0.2.2')) {
      return _baseUrl.replaceFirst('10.0.2.2', 'localhost');
    }

    return null;
  }

  static String get signalRHubUrl => '$apiBaseUrl/hubs/chat';

  static const String _googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );

  static String get googlePlacesApiKey => _googlePlacesApiKey;
}
