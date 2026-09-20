enum SyncOperation {
  create,
  update,
  delete,
  statusChange;

  String get code {
    switch (this) {
      case SyncOperation.create:
        return 'CREATE';
      case SyncOperation.update:
        return 'UPDATE';
      case SyncOperation.delete:
        return 'DELETE';
      case SyncOperation.statusChange:
        return 'STATUS_CHANGE';
    }
  }

  static SyncOperation fromString(String val) {
    switch (val.toUpperCase().trim()) {
      case 'CREATE':
      case 'INSERT':
        return SyncOperation.create;
      case 'UPDATE':
        return SyncOperation.update;
      case 'DELETE':
        return SyncOperation.delete;
      case 'STATUS_CHANGE':
        return SyncOperation.statusChange;
      default:
        return SyncOperation.update;
    }
  }
}
