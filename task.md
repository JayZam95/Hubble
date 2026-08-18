# Tasks for Agent A (Completed)
- [x] Create Analytics Dashboard with dark/glassmorphism theme and mocked metrics.
- [x] Link Analytics Dashboard from Settings Screen under Storefront Manager.
- [x] Add Filter icon to Explore Screen search bar to open Filter Bottom Sheet.
- [x] Implement Filter Bottom Sheet with Price Range, Distance, and Rating sliders.
- [x] Update Search Provider to include advanced search logic using these filters.

# Tasks for Agent B (Completed)
- [x] Implement Escrow Logic in payment_provider.dart (`holdInEscrow`, `releaseEscrow`).
- [x] Update `booking_detail_screen.dart` to support escrow functionality (Release Funds, Dispute, Job Finished).
- [x] Implement Stripe Integration for Wallet top-ups in payment_provider.dart and wallet_screen.dart.

# Tasks for Agent C (Completed)
- [x] Update `AuthRepository` (`lib/features/auth/data/repositories/auth_repository.dart`) to request FCM permission and store `fcmToken`.
- [x] Update Cloud Functions (`functions/index.js`) to add triggers for `onNewMessage` and `onBookingChange`.
- [x] Add share button and deep linking logic to `public_profile_screen.dart`
- [x] Update `booking_detail_screen.dart` to open a dispute dialog and write a document to `disputes` collection before changing status to DISPUTED

# Tasks for Agent D (Completed)
- [x] Create ProviderCalendarScreen with TableCalendar and dark/glassmorphism theme.
- [x] Link ProviderCalendarScreen from SettingsScreen.

# Tasks for Agent E (Completed)
- [x] Implement Animated Onboarding Flow with `PageView` and `smooth_page_indicator`.
- [x] Update `main.dart` to use `SharedPreferences` to show OnboardingScreen once, then default to `AuthGate`.

# Tasks for Agent F (Completed)
- [x] Implement Agora video calling UI in `video_call_screen.dart`
- [x] Add Video Call button to `chat_screen.dart` AppBar

# Tasks for Agent G (Completed)
- [x] Create KycVerificationScreen using image_picker.
- [x] Implement KYC mock upload and update Firestore kyc_verifications and users collections.
- [x] Update SettingsScreen to show KYC status and link to verification screen.

# Tasks for Agent H (Completed)
- [x] Implemented Ratings & Reviews in ReviewModel, ReviewRepository, ReviewSubmissionScreen, public_profile_screen.dart, and booking_detail_screen.dart.

# Tasks for Agent I (Completed)
- [x] Create RetailStorefrontScreen for a premium e-commerce app UI.
- [x] Implement Add to Cart and Checkout flow fetching provider listings.

# Tasks for Agent I (Completed)
- [x] Implement Polymorphic Profiles (Store vs Individual) in Settings UI and UserModel.

# Tasks for Agent J (Completed)
- [x] Build Service Portfolio UI & Reference Check in service_portfolio_screen.dart

# Tasks for Trust & Privacy Specialist (Completed)
- [x] Update UserModel -> ClientProfile to add bool allowsReferenceInquiries (default true). Update toMap/fromMap.
- [x] Add a toggle in SettingsScreen for users to opt in/out of being contacted as references.
- [x] Update chat_screen.dart to display a permanent UI banner for reference checks.

# Tasks for Onboarding Wizard Designer (Completed)
- [x] Overhaul StorefrontSetupScreen into a multi-step Guided Wizard using PageView.

# Tasks for Trust & Privacy Specialist (Completed)
- [x] Update UserModel -> ClientProfile to add bool allowsReferenceInquiries (default true). Update toMap/fromMap.
- [x] Add a toggle in SettingsScreen for users to opt in/out of being contacted as references.
- [x] Update chat_screen.dart to display a permanent UI banner for reference checks.

# Tasks for Dispute Resolution Architect (Completed)
- [x] Create dispute_model.dart.
- [x] Create dispute_center_screen.dart for photo upload and admin chat.
- [x] Update payment_provider.dart Escrow logic to lock funds in ESCROW_HOLD during disputes.

# Tasks for Shopping Cart Architect (Completed)
- [x] Create `cart_model.dart` and `cart_provider.dart` to manage global cart state.
- [x] Update `listing_detail_screen.dart` to support Add to Cart for products.
- [x] Create `cart_screen.dart` with Checkout button using Escrow Wallet.

# Tasks for Smart Dashboard Engineer (Completed)
- [x] Update DashboardScreen to check \UserModel.providerProfile.businessType\.
- [x] Create ServiceDashboardView with Focus on Jobs, Calendar, Hourly earnings.

# Tasks for Feed and E-commerce cart (Completed)
- [x] Wrap feed in explore_screen.dart with RefreshIndicator and invalidate allListingsProvider.
- [x] Ensure cart_provider.dart exists and works.
- [x] Add Shopping Cart icon to AppBar in explore_screen.dart with item count badge.
- [x] Build cart_screen.dart with Cart UI and Checkout functionality.

# Tasks for Auth and Onboarding UI Fixes (Completed)
- [x] 1. Added "Sign Up with Google" button mirroring the login_screen.dart in register_screen.dart.
- [x] 2. Added a TextFormField for "Full Name" in google_setup_screen.dart, prefilled, and updated completeGoogleSetup.
- [x] 3. Wrapped OnboardingScreen bottomSheet in a SafeArea and updated the SKIP button to directly call _onDone().

# Tasks for Booking Logic Fixer (Completed)
- [x] 1. `booking_provider.dart` map stream data to sort active bookings by `requestedAt` descending.
- [x] 2. `booking_detail_screen.dart` fix Action Buttons visibility to check `user.uid == booking.providerId` rather than global user role.

# Tasks for Maps and Profiles (Completed)
- [x] Add `bool isLocationShared` to ProviderProfile model.
- [x] Add SwitchListTile for "Share My Location on Map" in SettingsScreen.
- [x] Use geolocator to get user location in map_view_screen if shared. Connect filter button.
- [x] Add Message and Book Now buttons to service_portfolio_screen and retail_storefront_screen.

# Tasks for Empty States and Loading Fixes (Completed)
- [x] Fix empty/error states and incomplete stubs in `search_results_screen.dart`
- [x] Change suppressed loading states in `explore_screen.dart`
- [x] Replace raw error text with formatted error card in `booking_list_screen.dart`
- [x] Add premium empty state for `cart_screen.dart`
- [x] Hide Video calling initialization if App ID is unconfigured in `video_call_screen.dart`

# Provider Setup Wizard (Completed)
- [x] 1. Create `lib/features/profile/presentation/screens/provider_setup_wizard_screen.dart`.
- [x] 2. Ensure Finish button updates Firestore with businessType, category, etc.
- [x] 3. Update `settings_screen.dart` to remove old dialogs and navigate to the wizard.

# Real Dashboard Data (Completed)
- [x] 1. Create dashboard_provider.dart
- [x] 2. Update dashboard_screen.dart with real data.

# Tasks for Inbox UI Architect (Completed)
- [x] Upscale `inbox_screen.dart` with glassmorphic search bar, unread badges, swipe-to-delete, and online status.

# Tasks for Chat UI Upscaler (Completed)
- [x] Read Receipts: Add WhatsApp-style tick icons at the bottom corner of outgoing messages.
- [x] Glassmorphic Bubbles: Upgrade the incoming and outgoing message bubbles to use a premium frosted glass effect.
- [x] Smart Date Headers: Group the messages in the ListView with beautiful date pill dividers.
- [x] Enhanced Input: Make the bottom text input bar sleeker with glassmorphism.

# Tasks for Map UI Architect (Completed)
- [x] Ensure `url_launcher` is in `pubspec.yaml`.
- [x] Map Search: Add a floating search bar above the map to search for providers.
- [x] Polyline Directions: Manage state for a selected provider's LatLng. When a provider is tapped, draw a `PolylineLayer` between `_currentPosition` and the selected provider.
- [x] Navigation: In the provider Bottom Sheet, add a "Start Navigation" `ElevatedButton`. When tapped, launch Google Maps using `url_launcher`.

# Tasks for Inbox Presence Engineer (Completed)
- [x] Update user_model.dart to include isOnline and lastSeen.
- [x] Create user_presence_provider.dart.
- [x] Update inbox_screen.dart to use presence provider for avatars and online indicator.

# Task 1: Core Models & Providers for the Transportation vertical (Completed)
- [x] Create BusTripModel and SeatModel.
- [x] Create RideRequestModel.
- [x] Create transportation_provider with StreamProvider and dummy data logic.
