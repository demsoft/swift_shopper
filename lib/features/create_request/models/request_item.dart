class RequestItem {
  const RequestItem({
    required this.id,
    this.name = '',
    this.unit = '',
    this.description = '',
    this.price = 0.0,
    this.quantity = 1,
    this.maxPrice,
  });

  final String id;
  final String name;
  final String unit;
  final String description;
  final double price;
  final int quantity;
  final double? maxPrice;

  double get subtotal => price * quantity;

  RequestItem copyWith({
    String? id,
    String? name,
    String? unit,
    String? description,
    double? price,
    int? quantity,
    double? maxPrice,
    bool clearMaxPrice = false,
  }) {
    return RequestItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
    );
  }
}
