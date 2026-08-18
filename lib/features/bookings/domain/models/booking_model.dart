import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  disputed;

  // ignore: constant_identifier_names
  static const BookingStatus PENDING = BookingStatus.pending;
  // ignore: constant_identifier_names
  static const BookingStatus ACCEPTED = BookingStatus.accepted;
  // ignore: constant_identifier_names
  static const BookingStatus IN_PROGRESS = BookingStatus.inProgress;
  // ignore: constant_identifier_names
  static const BookingStatus COMPLETED = BookingStatus.completed;
  // ignore: constant_identifier_names
  static const BookingStatus CANCELLED = BookingStatus.cancelled;
  // ignore: constant_identifier_names
  static const BookingStatus DISPUTED = BookingStatus.disputed;

  String get displayName {
    switch (this) {
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.disputed:
        return 'Disputed';
    }
  }
}

class BookingFinancials {
  final double agreedPrice;
  final double platformFee;
  final double providerPayout;
  final bool isHeldInEscrow;
  final String paymentMethod; // 'escrow' or 'cash'

  BookingFinancials({
    required this.agreedPrice,
    required this.platformFee,
    required this.providerPayout,
    required this.isHeldInEscrow,
    this.paymentMethod = 'escrow',
  });

  Map<String, dynamic> toMap() {
    return {
      'agreedPrice': agreedPrice,
      'platformFee': platformFee,
      'providerPayout': providerPayout,
      'isHeldInEscrow': isHeldInEscrow,
      'paymentMethod': paymentMethod,
    };
  }

  factory BookingFinancials.fromMap(Map<String, dynamic> map) {
    return BookingFinancials(
      agreedPrice: (map['agreedPrice'] as num?)?.toDouble() ?? 0.0,
      platformFee: (map['platformFee'] as num?)?.toDouble() ?? 0.0,
      providerPayout: (map['providerPayout'] as num?)?.toDouble() ?? 0.0,
      isHeldInEscrow: map['isHeldInEscrow'] as bool? ?? false,
      paymentMethod: map['paymentMethod'] as String? ?? 'escrow',
    );
  }
}

class BookingTimestamps {
  final DateTime requestedAt;
  final DateTime scheduledFor;

  BookingTimestamps({
    required this.requestedAt,
    required this.scheduledFor,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestedAt': Timestamp.fromDate(requestedAt),
      'scheduledFor': Timestamp.fromDate(scheduledFor),
    };
  }

  factory BookingTimestamps.fromMap(Map<String, dynamic> map) {
    return BookingTimestamps(
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledFor: (map['scheduledFor'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class BookingModel {
  final String bookingId;
  final String clientId;
  final String providerId;
  final String clientName;
  final String providerName;
  final String serviceCategory;
  final BookingStatus status;
  final String jobDescription;
  final BookingFinancials financials;
  final BookingTimestamps timestamps;
  final String? listingId;
  final String billingType;
  final int quantity;

  BookingModel({
    required this.bookingId,
    required this.clientId,
    required this.providerId,
    required this.clientName,
    required this.providerName,
    required this.serviceCategory,
    required this.status,
    required this.jobDescription,
    required this.financials,
    required this.timestamps,
    this.listingId,
    this.billingType = 'fixed',
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'clientId': clientId,
      'providerId': providerId,
      'clientName': clientName,
      'providerName': providerName,
      'serviceCategory': serviceCategory,
      'status': status.name,
      'jobDescription': jobDescription,
      'financials': financials.toMap(),
      'timestamps': {
        'requestedAt': Timestamp.fromDate(timestamps.requestedAt),
        'scheduledFor': Timestamp.fromDate(timestamps.scheduledFor),
      },
      'listingId': listingId,
      'billingType': billingType,
      'quantity': quantity,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawStatus = (map['status'] as String? ?? 'pending').trim();
    final status = BookingStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == rawStatus.toLowerCase() ||
             e.name.replaceAll('_', '').toLowerCase() == rawStatus.replaceAll('_', '').toLowerCase(),
      orElse: () => BookingStatus.pending,
    );

    final financialsData = map['financials'];
    final financialsMap = financialsData is Map ? Map<String, dynamic>.from(financialsData) : <String, dynamic>{};

    final timestampsData = map['timestamps'];
    final timestampsMap = timestampsData is Map ? Map<String, dynamic>.from(timestampsData) : <String, dynamic>{};

    return BookingModel(
      bookingId: docId,
      clientId: map['clientId'] as String? ?? '',
      providerId: map['providerId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      providerName: map['providerName'] as String? ?? '',
      serviceCategory: map['serviceCategory'] as String? ?? '',
      status: status,
      jobDescription: map['jobDescription'] as String? ?? '',
      financials: BookingFinancials.fromMap(financialsMap),
      timestamps: BookingTimestamps.fromMap(timestampsMap),
      listingId: map['listingId'] as String?,
      billingType: map['billingType'] as String? ?? 'fixed',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
