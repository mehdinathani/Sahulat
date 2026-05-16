class ServiceProvider {
  final String id;
  final String name;
  final String serviceType;
  final String location;
  final double rating;
  final int pricePerHour;
  final bool availability;
  final double distance;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.location,
    required this.rating,
    required this.pricePerHour,
    required this.availability,
    required this.distance,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      serviceType: json['service_type'] ?? '',
      location: json['location'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      pricePerHour: json['price_per_hour'] ?? 0,
      availability: json['availability'] ?? false,
      distance: (json['distance'] ?? 0.0).toDouble(),
    );
  }
}
