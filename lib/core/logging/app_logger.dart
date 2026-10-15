import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

void logFailure(
  String event,
  Object error,
  StackTrace stackTrace, {
  required String scope,
}) {
  debugPrint('$scope.$event error=${error.runtimeType}');
  developer.log(
    event,
    name: scope,
    error: error.runtimeType,
    stackTrace: stackTrace,
    level: 1000,
  );
}

void logMetric(
  String event,
  Map<String, Object> fields, {
  required String scope,
}) {
  final values = fields.entries.map((entry) => '${entry.key}=${entry.value}');
  final message = '$scope.$event ${values.join(' ')}';
  debugPrint(message);
  developer.log(message, name: scope);
}
