class ProductSkuEntity {
  final String id;
  final String organizationId;
  final String skuCode;
  final String name;
  final String category;
  final String unit; // pcs, boxes, kgs, liters, cartons
  final double unitPrice;
  final double taxRate; // e.g. 18.0 for 18% GST / VAT
  final int stock;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;

  const ProductSkuEntity({
    required this.id,
    required this.organizationId,
    required this.skuCode,
    required this.name,
    required this.category,
    this.unit = 'pcs',
    required this.unitPrice,
    this.taxRate = 18.0,
    this.stock = 100,
    this.isActive = true,
    this.imageUrl,
    required this.createdAt,
  });

  ProductSkuEntity copyWith({
    String? id,
    String? organizationId,
    String? skuCode,
    String? name,
    String? category,
    String? unit,
    double? unitPrice,
    double? taxRate,
    int? stock,
    bool? isActive,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return ProductSkuEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      skuCode: skuCode ?? this.skuCode,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
