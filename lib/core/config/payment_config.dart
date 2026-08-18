class PaymentConfig {
  // Sandbox testing keys for Zambian Kwacha Mobile Money payments
  static const String flutterwavePublicKey = String.fromEnvironment(
    'FLUTTERWAVE_PUBLIC_KEY',
    defaultValue: 'FLWPUBK_TEST-DUMMY_KEY_FOR_BUILD',
  );
  static const String flutterwaveSecretKey = String.fromEnvironment(
    'FLUTTERWAVE_SECRET_KEY',
    defaultValue: 'FLWSECK_TEST-DUMMY_KEY_FOR_BUILD',
  );
  
  static const String baseUrl = 'https://api.flutterwave.com/v3';
  static const String chargeUrl = '$baseUrl/charges?type=mobile_money_zambia';
}
