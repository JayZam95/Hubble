/// Standardized Hero tag generator for Hubble.
/// Guarantees collision-free, predictable Hero animation tags between feeds and detail screens.
class HeroTags {
  static String listingImage(String id) => 'hero_listing_img_$id';
  static String listingTitle(String id) => 'hero_listing_title_$id';
  static String listingPrice(String id) => 'hero_listing_price_$id';
  static String listingCard(String id) => 'hero_listing_card_$id';
  static String userAvatar(String uid) => 'hero_avatar_$uid';
  static String userBadge(String uid) => 'hero_badge_$uid';
  static String categoryIcon(String category) => 'hero_category_icon_$category';
  static String bookingCard(String bookingId) => 'hero_booking_card_$bookingId';
  static String vehicleMarker(String vehicleId) => 'hero_vehicle_$vehicleId';
}
