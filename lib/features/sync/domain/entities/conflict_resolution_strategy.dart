enum ConflictResolutionStrategy {
  clientWins,
  serverWins,
  merge;

  String get displayName {
    switch (this) {
      case ConflictResolutionStrategy.clientWins:
        return 'Client Wins (Local Overrides)';
      case ConflictResolutionStrategy.serverWins:
        return 'Server Wins (Remote Overrides)';
      case ConflictResolutionStrategy.merge:
        return 'Merge (Fields Combine)';
    }
  }

  String get description {
    switch (this) {
      case ConflictResolutionStrategy.clientWins:
        return 'Field updates and completion timestamps take absolute precedence.';
      case ConflictResolutionStrategy.serverWins:
        return 'Remote server modifications override local pending changes.';
      case ConflictResolutionStrategy.merge:
        return 'Non-null local attributes are overlaid onto latest remote record.';
    }
  }
}
