import '../../domain/entities/product_sku_entity.dart';

class ProductSkuModel extends ProductSkuEntity {
  const ProductSkuModel({
    required super.id,
    required super.organizationId,
    required super.skuCode,
    required super.name,
    required super.category,
    super.unit,
    required super.unitPrice,
    super.taxRate,
    super.stock,
    super.isActive,
    super.imageUrl,
    required super.createdAt,
  });

  factory ProductSkuModel.fromEntity(ProductSkuEntity entity) {
    return ProductSkuModel(
      id: entity.id,
      organizationId: entity.organizationId,
      skuCode: entity.skuCode,
      name: entity.name,
      category: entity.category,
      unit: entity.unit,
      unitPrice: entity.unitPrice,
      taxRate: entity.taxRate,
      stock: entity.stock,
      isActive: entity.isActive,
      imageUrl: entity.imageUrl,
      createdAt: entity.createdAt,
    );
  }

  factory ProductSkuModel.fromJson(Map<String, dynamic> json) {
    return ProductSkuModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? 'org_default',
      skuCode: json['sku_code'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'General',
      unit: json['unit'] as String? ?? 'pcs',
      unitPrice: (json['unit_price'] as num).toDouble(),
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 18.0,
      stock: json['stock'] as int? ?? 100,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'sku_code': skuCode,
      'name': name,
      'category': category,
      'unit': unit,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
      'stock': stock,
      'is_active': isActive ? 1 : 0,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProductSkuModel.fromSqlMap(Map<String, dynamic> map) {
    return ProductSkuModel.fromJson(map);
  }

  Map<String, dynamic> toSqlMap() {
    return toJson();
  }
}
