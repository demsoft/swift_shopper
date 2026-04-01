import 'package:flutter/material.dart';

class QuickAction {
  const QuickAction({required this.title, required this.icon});
  final String title;
  final IconData icon;
}

class ActiveOrder {
  const ActiveOrder({
    required this.orderId,
    required this.title,
    required this.store,
    required this.status,
    this.shopperName = '',
    this.total = 0,
    this.deliveryFee = 0,
    this.serviceFee = 0,
    this.estimatedItemsTotal = 0,
    this.itemsSubtotal = 0,
    this.storePhotoUrl,
  });

  final String orderId;
  final String title;
  final String store;
  final String status;
  final String shopperName;
  final double total;
  final double deliveryFee;
  final double serviceFee;
  final double estimatedItemsTotal;
  final double itemsSubtotal;
  final String? storePhotoUrl;
}

class RecentRequest {
  const RecentRequest({
    required this.title,
    required this.date,
    required this.itemsCount,
  });

  final String title;
  final String date;
  final int itemsCount;
}

// ── Active Job (for shopper) ────────────────────────────────────────────

class ActiveJobData {
  const ActiveJobData({
    required this.orderId,
    required this.requestId,
    required this.storeName,
    required this.storeAddress,
    required this.customerName,
    required this.deliveryAddress,
    required this.deliveryNotes,
    required this.status,
    required this.pickedItemsCount,
    required this.totalItemsCount,
    required this.estimatedTotal,
    required this.items,
  });

  final String orderId;
  final String requestId;
  final String storeName;
  final String storeAddress;
  final String customerName;
  final String deliveryAddress;
  final String deliveryNotes;
  final int status;
  final int pickedItemsCount;
  final int totalItemsCount;
  final double estimatedTotal;
  final List<ActiveJobItem> items;
}

class ActiveJobItem {
  const ActiveJobItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.description,
    required this.quantity,
    required this.estimatedPrice,
    this.foundPrice,
    required this.status,
    this.photoUrl,
  });

  final int id;
  final String name;
  final String unit;
  final String description;
  final int quantity;
  final double estimatedPrice;
  final double? foundPrice;
  // 0=Pending, 1=Found, 2=Unavailable
  final int status;
  final String? photoUrl;
}

// ── Shopper Order History ────────────────────────────────────────────────

class ShopperOrderData {
  const ShopperOrderData({
    required this.orderId,
    required this.storeName,
    required this.customerName,
    required this.completedAt,
    required this.earningsAmount,
    required this.status,
    required this.itemsCount,
  });

  final String orderId;
  final String storeName;
  final String customerName;
  final String completedAt;
  final double earningsAmount;
  // 5=Delivered, 6=Cancelled
  final int status;
  final int itemsCount;

  bool get isCancelled => status == 6;
}

// ── Order Summary (customer) ─────────────────────────────────────────────

class OrderSummaryData {
  const OrderSummaryData({
    required this.orderId,
    required this.storeName,
    required this.storeAddress,
    required this.shopperName,
    required this.deliveryAddress,
    required this.deliveredAt,
    required this.items,
    required this.itemsSubtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.totalPaid,
  });

  final String orderId;
  final String storeName;
  final String storeAddress;
  final String shopperName;
  final String deliveryAddress;
  final String deliveredAt;
  final List<OrderSummaryItem> items;
  final double itemsSubtotal;
  final double deliveryFee;
  final double serviceFee;
  final double totalPaid;
}

class OrderSummaryItem {
  const OrderSummaryItem({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.price,
    this.photoUrl,
  });

  final String name;
  final String unit;
  final int quantity;
  final double price;
  final String? photoUrl;
}

// ── Order Tracking (customer) ────────────────────────────────────────────

class OrderTrackingData {
  const OrderTrackingData({
    required this.orderId,
    required this.shopperName,
    required this.storeName,
    required this.currentStatus,
    required this.stepLabel,
    required this.progressPercent,
    required this.pickedItemsCount,
    required this.totalItemsCount,
    required this.estimatedDeliveryMinutes,
  });

  final String orderId;
  final String shopperName;
  final String storeName;
  final String currentStatus;
  final String stepLabel;
  final int progressPercent;
  final int pickedItemsCount;
  final int totalItemsCount;
  final int estimatedDeliveryMinutes;
}

// ── Available Request (for shoppers) ────────────────────────────────────────

class AvailableRequestItem {
  const AvailableRequestItem({
    required this.name,
    required this.unit,
    required this.description,
    required this.quantity,
    required this.price,
  });

  final String name;
  final String unit;
  final String description;
  final int quantity;
  final double price;
}

class AvailableRequestData {
  const AvailableRequestData({
    required this.requestId,
    required this.preferredStore,
    required this.marketType,
    required this.budget,
    required this.deliveryAddress,
    required this.itemsCount,
    required this.items,
    required this.createdAt,
  });

  final String requestId;
  final String preferredStore;
  final String marketType;
  final double budget;
  final String deliveryAddress;
  final int itemsCount;
  final List<AvailableRequestItem> items;
  final String createdAt;

  List<String> get itemNames => items.map((i) => i.name).toList();
}

class MarketData {
  const MarketData({
    required this.marketId,
    required this.name,
    required this.type,
    required this.address,
    required this.openingTime,
    required this.closingTime,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.categories = const [],
  });

  final String marketId;
  final String name;
  final String type;
  final String address;
  final String openingTime;
  final String closingTime;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final List<String> categories;
}
