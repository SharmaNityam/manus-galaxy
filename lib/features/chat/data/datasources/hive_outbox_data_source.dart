import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../domain/entities/pending_operation.dart';

class HiveOutboxDataSource {
  const HiveOutboxDataSource(this._box);

  final Box<Map> _box;

  Future<void> enqueue(PendingOperation operation) async {
    if (_box.containsKey(operation.id)) return;
    await _box.put(operation.id, operation.toMap());
  }

  Future<List<PendingOperation>> pending() async {
    final operations = _box.values
        .map(PendingOperation.fromMap)
        .toList(growable: false);
    return operations.toList()..sort((a, b) {
      final dateOrder = a.createdAt.compareTo(b.createdAt);
      return dateOrder == 0 ? a.id.compareTo(b.id) : dateOrder;
    });
  }

  Future<void> remove(String id) => _box.delete(id);

  Future<int> count() async => _box.length;

  Future<bool> contains(String id) async => _box.containsKey(id);
}
