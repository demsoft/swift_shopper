enum SenderType { shopper, customer }

enum MessageType { text, image, priceCard }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.type,
    required this.time,
    this.text,
    this.imageUrl,
    this.priceCardData,
  });

  final String id;
  final SenderType sender;
  final MessageType type;
  final DateTime time;
  final String? text;
  final String? imageUrl;
  final PriceCardData? priceCardData;
}

class PriceCardData {
  const PriceCardData({
    required this.itemName,
    required this.imageUrl,
    required this.price,
  });

  final String itemName;
  final String imageUrl;
  final double price;
}
