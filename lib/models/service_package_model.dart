class ServicePackageModel {
  final String id;
  final String name;
  final String duration;
  final int price; // in USD
  final List<String> features;
  final bool isPopular;

  const ServicePackageModel({
    required this.id,
    required this.name,
    required this.duration,
    required this.price,
    required this.features,
    this.isPopular = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'duration': duration,
    'price': price,
    'features': features,
    'isPopular': isPopular,
  };

  factory ServicePackageModel.fromMap(Map<String, dynamic> map) =>
      ServicePackageModel(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        duration: map['duration'] as String? ?? '',
        price: (map['price'] as num?)?.toInt() ?? 0,
        features: List<String>.from(map['features'] as List? ?? []),
        isPopular: map['isPopular'] as bool? ?? false,
      );

  ServicePackageModel copyWith({
    String? id,
    String? name,
    String? duration,
    int? price,
    List<String>? features,
    bool? isPopular,
  }) => ServicePackageModel(
    id: id ?? this.id,
    name: name ?? this.name,
    duration: duration ?? this.duration,
    price: price ?? this.price,
    features: features ?? this.features,
    isPopular: isPopular ?? this.isPopular,
  );
}
