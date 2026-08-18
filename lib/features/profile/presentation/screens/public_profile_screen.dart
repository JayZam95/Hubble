import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_model.dart';
import 'retail_storefront_screen.dart';
import 'tutor_profile_screen.dart';
import 'handyman_profile_screen.dart';
import 'driver_profile_screen.dart';
import 'doctor_profile_screen.dart';
import 'service_portfolio_screen.dart';

class PublicProfileScreen extends ConsumerWidget {
  final UserModel providerUser;

  const PublicProfileScreen({super.key, required this.providerUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = providerUser.providerProfile;
    final businessType = profile.businessType.toLowerCase().trim();
    final category = profile.category.toLowerCase().trim();
    final profession = profile.professionTitle.toLowerCase().trim();
    final combined = '$category $profession $businessType';

    // 1. Shop / Retail Storefront
    if (businessType == 'shop' ||
        category.contains('retail') ||
        category.contains('clothing') ||
        category.contains('electronics') ||
        category.contains('groceries') ||
        category.contains('furniture') ||
        category.contains('hardware & tools') ||
        category.contains('shop') ||
        category.contains('store') ||
        category.contains('apparel')) {
      return RetailStorefrontScreen(providerUser: providerUser);
    }

    // 2. Tutor / Education
    if (combined.contains('tutor') ||
        combined.contains('education') ||
        combined.contains('teacher') ||
        combined.contains('instructor') ||
        combined.contains('academic') ||
        combined.contains('teaching') ||
        combined.contains('lesson') ||
        combined.contains('curriculum') ||
        combined.contains('math') ||
        combined.contains('science tutor') ||
        combined.contains('stem') ||
        combined.contains('lecture') ||
        combined.contains('school')) {
      return TutorProfileScreen(providerUser: providerUser);
    }

    // 3. Handyman / Repairs / Trades / Plumbing / Electrical
    if (combined.contains('handyman') ||
        combined.contains('plumb') ||
        combined.contains('electric') ||
        combined.contains('trade') ||
        combined.contains('repair') ||
        combined.contains('carpenter') ||
        combined.contains('mason') ||
        combined.contains('roof') ||
        combined.contains('contractor') ||
        combined.contains('painting') ||
        combined.contains('mechanic') ||
        combined.contains('appliance') ||
        combined.contains('renovation') ||
        combined.contains('home repair') ||
        combined.contains('welder') ||
        combined.contains('hvac') ||
        combined.contains('maintenance')) {
      return HandymanProfileScreen(providerUser: providerUser);
    }

    // 4. Driver / Boda / Cab / Transport / Delivery
    if (combined.contains('driver') ||
        combined.contains('boda') ||
        combined.contains('cab') ||
        combined.contains('taxi') ||
        combined.contains('transport') ||
        combined.contains('ride') ||
        combined.contains('delivery') ||
        combined.contains('chauffeur') ||
        combined.contains('courier') ||
        combined.contains('logistics') ||
        combined.contains('rider')) {
      return DriverProfileScreen(providerUser: providerUser);
    }

    // 5. Doctor / Medical / Healthcare
    if (combined.contains('doctor') ||
        combined.contains('medical') ||
        combined.contains('health') ||
        combined.contains('physician') ||
        combined.contains('clinic') ||
        combined.contains('therap') ||
        combined.contains('dentist') ||
        combined.contains('nurse') ||
        combined.contains('surgeon') ||
        combined.contains('pediatric') ||
        combined.contains('optometrist') ||
        combined.contains('pharm') ||
        combined.contains('psych') ||
        combined.contains('consultant physician')) {
      return DoctorProfileScreen(providerUser: providerUser);
    }

    // 6. Other / General Service Portfolio
    return ServicePortfolioScreen(providerUser: providerUser);
  }
}
