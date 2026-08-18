enum VehicleType { car, motorbike }
enum RideRequestStatus { pending, accepted, inProgress, completed }

class RideRequestModel {
  final String id;
  final String clientId;
  final String? driverId;
  final String pickupLocation;
  final String dropoffLocation;
  final VehicleType vehicleType;
  final RideRequestStatus status;
  final double price;
  final DateTime createdAt;

  RideRequestModel({
    required this.id,
    required this.clientId,
    this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.vehicleType,
    required this.status,
    required this.price,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'driverId': driverId,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'vehicleType': vehicleType.name,
      'status': status.name,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RideRequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RideRequestModel(
      id: documentId,
      clientId: map['clientId'] ?? '',
      driverId: map['driverId'],
      pickupLocation: map['pickupLocation'] ?? '',
      dropoffLocation: map['dropoffLocation'] ?? '',
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == map['vehicleType'],
        orElse: () => VehicleType.car,
      ),
      status: RideRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RideRequestStatus.pending,
      ),
      price: (map['price'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  RideRequestModel copyWith({
    String? id,
    String? clientId,
    String? driverId,
    String? pickupLocation,
    String? dropoffLocation,
    VehicleType? vehicleType,
    RideRequestStatus? status,
    double? price,
    DateTime? createdAt,
  }) {
    return RideRequestModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      driverId: driverId ?? this.driverId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      vehicleType: vehicleType ?? this.vehicleType,
      status: status ?? this.status,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
