import 'dart:convert';

class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.description,
  });

  final String placeId;
  final String description;

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'place_id': placeId,
        'description': description,
      };

  static List<PlacePrediction> listFromJsonString(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PlacePrediction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJsonString(List<PlacePrediction> predictions) {
    return jsonEncode(predictions.map((p) => p.toJson()).toList());
  }
}

class PlaceResult {
  const PlaceResult({
    required this.placeId,
    required this.description,
    required this.lat,
    required this.lng,
  });

  final String placeId;
  final String description;
  final double lat;
  final double lng;
}
