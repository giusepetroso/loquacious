class MigrationException implements Exception {
  final int _targetVersion;
  final String _targetDirection;
  final String _errorMessage;
  MigrationException(this._targetVersion, this._targetDirection, this._errorMessage);

  String get message {
    return 'Migrating $_targetDirection to version $_targetVersion went wrong: $_errorMessage';
  }

  @override
  String toString(){
    return this.message;
  }
}