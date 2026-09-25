import 'dart:convert';
import '../../domain/entities/sales_order_entity.dart';
import 'sales_order_item_model.dart';

class SalesOrderModel extends SalesOrderEntity {
  const SalesOrderModel({
    required super.id,
    required super.organizationId,
    required super.orderNumber,
    required super.customerId,
    required super.customerName,
    super.locationId,
    required super.userId,
    required super.userName,
    required super.orderDate,
    required super.items,
    required super.subtotal,
    required super.taxTotal,
    required super.grandTotal,
    super.status,
    super.paymentMethod,
    super.notes,
    required super.createdAt,
    super.synced,
  });

  factory SalesOrderModel.fromEntity(SalesOrderEntity entity) {
    return SalesOrderModel(
      id: entity.id,
      organizationId: entity.organizationId,
      orderNumber: entity.orderNumber,
      customerId: entity.customerId,
      customerName: entity.customerName,
      locationId: entity.locationId,
      userId: entity.userId,
      userName: entity.userName,
      orderDate: entity.orderDate,
      items: entity.items,
      subtotal: entity.subtotal,
      taxTotal: entity.taxTotal,
      grandTotal: entity.grandTotal,
      status: entity.status,
      paymentMethod: entity.paymentMethod,
      notes: entity.notes,
      createdAt: entity.createdAt,
      synced: entity.synced,
    );
  }

  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    List<SalesOrderItemModel> parsedItems = [];
    if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((item) => SalesOrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return SalesOrderModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? 'org_default',
      orderNumber: json['order_number'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String,
      locationId: json['location_id'] as String?,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Field Executive',
      orderDate: json['order_date'] as String,
      items: parsedItems,
      subtotal: (json['subtotal'] as num).toDouble(),
      taxTotal: (json['tax_total'] as num).toDouble(),
      grandTotal: (json['grand_total'] as num).toDouble(),
      status: SalesOrderStatus.fromString(json['status'] as String?),
      paymentMethod: SalesOrderPaymentMethod.fromString(json['payment_method'] as String?),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      synced: json['synced'] == 1 || json['synced'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'order_number': orderNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'location_id': locationId,
      'user_id': userId,
      'user_name': userName,
      'order_date': orderDate,
      'items': items.map((i) => SalesOrderItemModel.fromEntity(i).toJson()).toList(),
      'subtotal': subtotal,
      'tax_total': taxTotal,
      'grand_total': grandTotal,
      'status': status.name,
      'payment_method': paymentMethod.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'order_number': orderNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'location_id': locationId,
      'user_id': userId,
      'user_name': userName,
      'order_date': orderDate,
      'items_json': jsonEncode(items.map((i) => SalesOrderItemModel.fromEntity(i).toJson()).toList()),
      'subtotal': subtotal,
      'tax_total': taxTotal,
      'grand_total': grandTotal,
      'status': status.name,
      'payment_method': paymentMethod.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory SalesOrderModel.fromSqlMap(Map<String, dynamic> map) {
    List<SalesOrderItemModel> parsedItems = [];
    if (map['items_json'] != null) {
      try {
        final decoded = jsonDecode(map['items_json'] as String) as List;
        parsedItems = decoded
            .map((item) => SalesOrderItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return SalesOrderModel(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String? ?? 'org_default',
      orderNumber: map['order_number'] as String,
      customerId: map['customer_id'] as String,
      customerName: map['customer_name'] as String,
      locationId: map['location_id'] as String?,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String? ?? 'Field Executive',
      orderDate: map['order_date'] as String,
      items: parsedItems,
      subtotal: (map['subtotal'] as num).toDouble(),
      taxTotal: (map['tax_total'] as num).toDouble(),
      grandTotal: (map['grand_total'] as num).toDouble(),
      status: SalesOrderStatus.fromString(map['status'] as String?),
      paymentMethod: SalesOrderPaymentMethod.fromString(map['payment_method'] as String?),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      synced: map['synced'] == 1 || map['synced'] == true,
    );
  }
}
