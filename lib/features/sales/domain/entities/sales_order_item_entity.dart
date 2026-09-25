class SalesOrderItemEntity {
  final String id;
  final String productId;
  final String skuCode;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double taxRate; // percentage e.g. 18.0
  final double discountPct; // discount percentage e.g. 5.0

  const SalesOrderItemEntity({
    required this.id,
    required this.productId,
    required this.skuCode,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.taxRate = 18.0,
    this.discountPct = 0.0,
  });

  /// Subtotal before taxes: (unitPrice * quantity) - discount
  double get subtotal {
    final raw = unitPrice * quantity;
    final discount = raw * (discountPct / 100.0);
    return double.parse((raw - discount).toStringAsFixed(2));
  }

  /// Tax calculated on subtotal
  double get taxAmount {
    return double.parse((subtotal * (taxRate / 100.0)).toStringAsFixed(2));
  }

  /// Final line total including tax
  double get lineTotal {
    return double.parse((subtotal + taxAmount).toStringAsFixed(2));
  }

  SalesOrderItemEntity copyWith({
    String? id,
    String? productId,
    String? skuCode,
    String? productName,
    double? unitPrice,
    int? quantity,
    double? taxRate,
    double? discountPct,
  }) {
    return SalesOrderItemEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      skuCode: skuCode ?? this.skuCode,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      taxRate: taxRate ?? this.taxRate,
      discountPct: discountPct ?? this.discountPct,
    );
  }
}
