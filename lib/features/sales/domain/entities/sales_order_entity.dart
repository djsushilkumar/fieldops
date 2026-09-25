import 'sales_order_item_entity.dart';

enum SalesOrderStatus {
  draft,
  submitted,
  confirmed,
  dispatched,
  delivered,
  cancelled;

  static SalesOrderStatus fromString(String? val) {
    if (val == null) return SalesOrderStatus.draft;
    return SalesOrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => SalesOrderStatus.draft,
    );
  }
}

enum SalesOrderPaymentMethod {
  cash,
  credit30Days,
  upiQr,
  bankTransfer,
  cheque;

  static SalesOrderPaymentMethod fromString(String? val) {
    if (val == null) return SalesOrderPaymentMethod.cash;
    return SalesOrderPaymentMethod.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => SalesOrderPaymentMethod.cash,
    );
  }

  String get displayName {
    switch (this) {
      case SalesOrderPaymentMethod.cash:
        return 'Cash on Delivery (COD)';
      case SalesOrderPaymentMethod.credit30Days:
        return '30-Day Credit Line';
      case SalesOrderPaymentMethod.upiQr:
        return 'UPI / Instant QR';
      case SalesOrderPaymentMethod.bankTransfer:
        return 'NEFT / Bank Transfer';
      case SalesOrderPaymentMethod.cheque:
        return 'Cheque';
    }
  }
}

class SalesOrderEntity {
  final String id;
  final String organizationId;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String? locationId;
  final String userId;
  final String userName;
  final String orderDate;
  final List<SalesOrderItemEntity> items;
  final double subtotal;
  final double taxTotal;
  final double grandTotal;
  final SalesOrderStatus status;
  final SalesOrderPaymentMethod paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final bool synced;

  const SalesOrderEntity({
    required this.id,
    required this.organizationId,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    this.locationId,
    required this.userId,
    required this.userName,
    required this.orderDate,
    required this.items,
    required this.subtotal,
    required this.taxTotal,
    required this.grandTotal,
    this.status = SalesOrderStatus.submitted,
    this.paymentMethod = SalesOrderPaymentMethod.cash,
    this.notes,
    required this.createdAt,
    this.synced = false,
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  SalesOrderEntity copyWith({
    String? id,
    String? organizationId,
    String? orderNumber,
    String? customerId,
    String? customerName,
    String? locationId,
    String? userId,
    String? userName,
    String? orderDate,
    List<SalesOrderItemEntity>? items,
    double? subtotal,
    double? taxTotal,
    double? grandTotal,
    SalesOrderStatus? status,
    SalesOrderPaymentMethod? paymentMethod,
    String? notes,
    DateTime? createdAt,
    bool? synced,
  }) {
    return SalesOrderEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      locationId: locationId ?? this.locationId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      orderDate: orderDate ?? this.orderDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxTotal: taxTotal ?? this.taxTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }
}
