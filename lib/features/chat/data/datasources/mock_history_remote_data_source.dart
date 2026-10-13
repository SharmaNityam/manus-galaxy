import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../domain/entities/pending_operation.dart';

class MockHistoryRemoteDataSource {
  const MockHistoryRemoteDataSource({
    required Box<Map> appliedOperations,
    required Box<Map> remoteHistory,
  }) : _appliedOperations = appliedOperations,
       _remoteHistory = remoteHistory;

  final Box<Map> _appliedOperations;
  final Box<Map> _remoteHistory;

  Future<bool> apply(PendingOperation operation) async {
    if (_appliedOperations.containsKey(operation.id)) return false;

    final record = Map<String, Object?>.from(
      _remoteHistory.get(operation.conversationId) ?? const {},
    );
    final remoteUpdatedAt = DateTime.tryParse(
      record['updatedAt'] as String? ?? '',
    );
    if (remoteUpdatedAt != null &&
        remoteUpdatedAt.isAfter(operation.createdAt)) {
      await _appliedOperations.put(operation.id, operation.toMap());
      return true;
    }
    switch (operation.type) {
      case ChatOperationType.rename:
        record['title'] = operation.payload['title'];
        record['deleted'] = false;
      case ChatOperationType.pin:
        record['isPinned'] = operation.payload['isPinned'];
        record['deleted'] = false;
      case ChatOperationType.delete:
        record['deleted'] = true;
      case ChatOperationType.send:
        final messages = (record['messages'] as List? ?? []).cast<String>();
        record['messages'] = [
          ...messages,
          operation.payload['prompt'] as String,
        ];
        record['deleted'] = false;
    }
    record['updatedAt'] = operation.createdAt.toIso8601String();
    await _remoteHistory.put(operation.conversationId, record);
    await _appliedOperations.put(operation.id, operation.toMap());
    return true;
  }

  Future<int> appliedCount(String operationId) async =>
      _appliedOperations.containsKey(operationId) ? 1 : 0;
}
