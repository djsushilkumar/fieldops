class TeamEntity {
  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final String? leadManagerId;
  final String? leadManagerName;
  final String colorHex;
  final int memberCount;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeamEntity({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    this.leadManagerId,
    this.leadManagerName,
    this.colorHex = '#0288D1',
    this.memberCount = 0,
    this.memberIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  TeamEntity copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? description,
    String? leadManagerId,
    String? leadManagerName,
    String? colorHex,
    int? memberCount,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      description: description ?? this.description,
      leadManagerId: leadManagerId ?? this.leadManagerId,
      leadManagerName: leadManagerName ?? this.leadManagerName,
      colorHex: colorHex ?? this.colorHex,
      memberCount: memberCount ?? this.memberCount,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
