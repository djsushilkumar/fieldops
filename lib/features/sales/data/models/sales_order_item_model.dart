import '../../domain/entities/sales_order_item_entity.dart';

class SalesOrderItemModel extends SalesOrderItemEntity {
  const SalesOrderItemModel({
    required super.id,
    required super.productId,
    required super.skuCode,
    required super.productName,
    required super.unitPrice,
    required super.quantity,
    super.taxRate,
    super.discountPct,
  });

  factory SalesOrderItemModel.fromEntity(SalesOrderItemEntity entity) {
    return SalesOrderItemModel(
      id: entity.id,
      productId: entity.productId,
      skuCode: entity.skuCode,
      productName: entity.productName,
      unitPrice: entity.unitPrice,
      quantity: entity.quantity,
      taxRate: entity.taxRate,
      discountPct: entity.discountPct,
    );
  }

  factory SalesOrderItemModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      skuCode: json['sku_code'] as String,
      productName: json['product_name'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 18.0,
      discountPct: (json['discount_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'sku_code': skuCode,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'tax_rate': taxRate,
      'discount_pct': discountPct,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'line_total': lineTotal,
    };
  }
}
