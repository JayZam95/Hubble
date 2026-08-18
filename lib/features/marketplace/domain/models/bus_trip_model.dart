enum SeatStatus { available, booked, locked }

class SeatModel {
  final String id;
  final SeatStatus status;

  SeatModel({
    required this.id,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status.name,
    };
  }

  factory SeatModel.fromMap(Map<String, dynamic> map) {
    final statusStr = (map['status'] ?? '').toString().toLowerCase();
    SeatStatus parsedStatus = SeatStatus.available;
    if (statusStr == 'booked') {
      parsedStatus = SeatStatus.booked;
    } else if (statusStr == 'locked') {
      parsedStatus = SeatStatus.locked;
    }
    return SeatModel(
      id: map['id'] ?? '',
      status: parsedStatus,
    );
  }

  SeatModel copyWith({
    String? id,
    SeatStatus? status,
  }) {
    return SeatModel(
      id: id ?? this.id,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeatModel && other.id == id && other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, status);
}

class BusTripModel {
  final String id;
  final String companyName;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final List<SeatModel> seats;
  final String busClass;
  final int totalSeats;
  final int companyColorValue;

  BusTripModel({
    required this.id,
    required this.companyName,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.seats,
    required this.busClass,
    required this.totalSeats,
    required this.companyColorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'origin': origin,
      'destination': destination,
      'departureTime': departureTime.toIso8601String(),
      'arrivalTime': arrivalTime.toIso8601String(),
      'price': price,
      'seats': seats.map((x) => x.toMap()).toList(),
      'busClass': busClass,
      'totalSeats': totalSeats,
      'companyColorValue': companyColorValue,
    };
  }

  factory BusTripModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BusTripModel(
      id: documentId,
      companyName: map['companyName'] ?? '',
      origin: map['origin'] ?? 'Lusaka',
      destination: map['destination'] ?? '',
      departureTime: map['departureTime'] != null
          ? DateTime.parse(map['departureTime'])
          : DateTime.now(),
      arrivalTime: map['arrivalTime'] != null
          ? DateTime.parse(map['arrivalTime'])
          : DateTime.now().add(const Duration(hours: 6)),
      price: (map['price'] ?? 0.0).toDouble(),
      seats: map['seats'] != null
          ? List<SeatModel>.from(map['seats']?.map((x) => SeatModel.fromMap(x)))
          : [],
      busClass: map['busClass'] ?? 'Standard',
      totalSeats: map['totalSeats'] ?? 50,
      companyColorValue: map['companyColorValue'] ?? 0xFF10B981,
    );
  }

  BusTripModel copyWith({
    String? id,
    String? companyName,
    String? origin,
    String? destination,
    DateTime? departureTime,
    DateTime? arrivalTime,
    double? price,
    List<SeatModel>? seats,
    String? busClass,
    int? totalSeats,
    int? companyColorValue,
  }) {
    return BusTripModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      price: price ?? this.price,
      seats: seats ?? this.seats,
      busClass: busClass ?? this.busClass,
      totalSeats: totalSeats ?? this.totalSeats,
      companyColorValue: companyColorValue ?? this.companyColorValue,
    );
  }

  int get availableCount => seats.where((s) => s.status == SeatStatus.available).length;
}
