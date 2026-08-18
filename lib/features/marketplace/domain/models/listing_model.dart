
enum ListingType {
  product,
  service;

  String toJson() => name;

  static ListingType fromJson(String value) {
    return ListingType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ListingType.service,
    );
  }
}

enum BillingType {
  hourly,
  fixed,
  monthly,
  perItem;

  String toJson() => name;

  static BillingType fromJson(String value) {
    return BillingType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => BillingType.fixed,
    );
  }
}

class ListingModel {
  final String id;
  final String providerId;
  final String providerName;
  final String providerImage;
  final String title;
  final String description;
  final double price;
  final ListingType listingType;
  final BillingType billingType;
  final String category;
  final List<String> images;
  final int stockCount; // Used for physical goods
  
  // Service specific fields
  final String? estimatedDuration;
  final bool travelsToClient;
  final int? travelRadius;
  final bool isVariablePrice;
  
  final DateTime createdAt;

  ListingModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.providerImage,
    required this.title,
    required this.description,
    required this.price,
    required this.listingType,
    required this.billingType,
    required this.category,
    required this.images,
    required this.stockCount,
    this.estimatedDuration,
    this.travelsToClient = false,
    this.travelRadius,
    this.isVariablePrice = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': id,
      'providerId': providerId,
      'providerName': providerName,
      'providerImage': providerImage,
      'title': title,
      'description': description,
      'price': price,
      'listingType': listingType.toJson(),
      'billingType': billingType.toJson(),
      'category': category,
      'images': images,
      'stockCount': stockCount,
      'estimatedDuration': estimatedDuration,
      'travelsToClient': travelsToClient,
      'travelRadius': travelRadius,
      'isVariablePrice': isVariablePrice,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ListingModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawListingType = map['listingType'] as String? ?? 'service';
    final rawBillingType = map['billingType'] as String? ?? 'fixed';

    return ListingModel(
      id: docId,
      providerId: map['providerId'] as String? ?? '',
      providerName: map['providerName'] as String? ?? '',
      providerImage: map['providerImage'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      listingType: ListingType.fromJson(rawListingType),
      billingType: BillingType.fromJson(rawBillingType),
      category: map['category'] as String? ?? '',
      images: List<String>.from(map['images'] as List? ?? []),
      stockCount: map['stockCount'] as int? ?? 0,
      estimatedDuration: map['estimatedDuration'] as String?,
      travelsToClient: map['travelsToClient'] as bool? ?? false,
      travelRadius: map['travelRadius'] as int?,
      isVariablePrice: map['isVariablePrice'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is String
              ? DateTime.parse(map['createdAt'])
              : (map['createdAt'] as dynamic).toDate())
          : DateTime.now(),
    );
  }
}
