enum ColumnType {
  text,
  integer,
  real,
  blob,
}

class ColumnDefinition {
  final String name;
  final ColumnType type;
  final bool isPrimaryKey;
  final bool isNullable;
  final dynamic defaultValue;

  const ColumnDefinition({
    required this.name,
    required this.type,
    this.isPrimaryKey = false,
    this.isNullable = true,
    this.defaultValue,
  });

  String toSql() {
    final buffer = StringBuffer('$name ');
    switch (type) {
      case ColumnType.text:
        buffer.write('TEXT');
        break;
      case ColumnType.integer:
        buffer.write('INTEGER');
        break;
      case ColumnType.real:
        buffer.write('REAL');
        break;
      case ColumnType.blob:
        buffer.write('BLOB');
        break;
    }
    if (isPrimaryKey) {
      buffer.write(' PRIMARY KEY');
    }
    if (!isNullable) {
      buffer.write(' NOT NULL');
    }
    if (defaultValue != null) {
      buffer.write(' DEFAULT ');
      if (defaultValue is String) {
        buffer.write("'$defaultValue'");
      } else {
        buffer.write('$defaultValue');
      }
    }
    return buffer.toString();
  }
}

class DatabaseTable {
  final String name;
  final List<ColumnDefinition> columns;
  final List<String> indexes;

  const DatabaseTable({
    required this.name,
    required this.columns,
    this.indexes = const [],
  });

  String get createTableSql {
    final colSql = columns.map((c) => c.toSql()).join(',\n  ');
    return 'CREATE TABLE IF NOT EXISTS $name (\n  $colSql\n);';
  }

  List<String> get createIndexesSql {
    final list = <String>[];
    for (int i = 0; i < indexes.length; i++) {
      final col = indexes[i];
      list.add('CREATE INDEX IF NOT EXISTS idx_${name}_$col ON $name ($col);');
    }
    return list;
  }

  ColumnDefinition? get primaryKey {
    for (final col in columns) {
      if (col.isPrimaryKey) return col;
    }
    return null;
  }
}
