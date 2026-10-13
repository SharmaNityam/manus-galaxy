import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/datasources/network_status_source.dart';
import '../../domain/entities/pending_operation.dart';
import '../../domain/repositories/chat_repository.dart';

enum SyncStatus { checking, offline, online, syncing, failed }

class OutboxSyncCoordinator extends ChangeNotifier {
  OutboxSyncCoordinator({
    required ChatRepository repository,
    required NetworkStatusSource networkStatus,
  }) : _repository = repository,
       _networkStatus = networkStatus;

  final ChatRepository _repository;
  final NetworkStatusSource _networkStatus;
  StreamSubscription<bool>? _subscription;
  final _appliedOperations = StreamController<PendingOperation>.broadcast();
  SyncStatus status = SyncStatus.checking;
  int pendingCount = 0;
  String? errorMessage;
  Stream<PendingOperation> get appliedOperations => _appliedOperations.stream;
  Future<void>? _syncing;

  bool get isOnline =>
      status == SyncStatus.online || status == SyncStatus.syncing;

  Future<void> start() async {
    _subscription = _networkStatus.changes.listen(_onConnectivityChanged);
    await _onConnectivityChanged(await _networkStatus.isOnline());
  }

  Future<void> refresh() async {
    pendingCount = await _repository.pendingOperationCount();
    notifyListeners();
    if (isOnline) await _sync();
  }

  Future<void> retry() => _sync();

  Future<void> _onConnectivityChanged(bool online) async {
    if (!online) {
      status = SyncStatus.offline;
      pendingCount = await _repository.pendingOperationCount();
      notifyListeners();
      return;
    }
    status = SyncStatus.online;
    notifyListeners();
    await _sync();
  }

  Future<void> _sync() {
    final active = _syncing;
    if (active != null) return active;
    final run = _runSync();
    _syncing = run.whenComplete(() => _syncing = null);
    return _syncing!;
  }

  Future<void> _runSync() async {
    pendingCount = await _repository.pendingOperationCount();
    if (pendingCount == 0) {
      status = SyncStatus.online;
      errorMessage = null;
      notifyListeners();
      return;
    }
    status = SyncStatus.syncing;
    notifyListeners();
    try {
      final applied = await _repository.replayQueuedOperations();
      for (final operation in applied) {
        _appliedOperations.add(operation);
      }
      pendingCount = await _repository.pendingOperationCount();
      status = SyncStatus.online;
      errorMessage = null;
    } catch (error) {
      pendingCount = await _repository.pendingOperationCount();
      status = SyncStatus.failed;
      errorMessage = 'Some changes could not sync. Try again.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _appliedOperations.close();
    super.dispose();
  }
}
