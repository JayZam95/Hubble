import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../domain/models/bus_trip_model.dart';
import '../../providers/transportation_provider.dart';
import 'bus_receipt_screen.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
enum _PaymentNetwork { mtn, airtel, zamtel }

extension _NetworkLabel on _PaymentNetwork {
  String get label {
    switch (this) {
      case _PaymentNetwork.mtn:
        return 'MTN Zambia';
      case _PaymentNetwork.airtel:
        return 'Airtel Money';
      case _PaymentNetwork.zamtel:
        return 'Zamtel Kwacha';
    }
  }

  Color get color {
    switch (this) {
      case _PaymentNetwork.mtn:
        return const Color(0xFFFFCC00);
      case _PaymentNetwork.airtel:
        return const Color(0xFFE4002B);
      case _PaymentNetwork.zamtel:
        return const Color(0xFF00A651);
    }
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class BusCheckoutScreen extends ConsumerStatefulWidget {
  final BusTripModel trip;
  final List<SeatModel> selectedSeats;
  final DateTime travelDate;

  const BusCheckoutScreen({
    super.key,
    required this.trip,
    required this.selectedSeats,
    required this.travelDate,
  });

  @override
  ConsumerState<BusCheckoutScreen> createState() => _BusCheckoutScreenState();
}

class _BusCheckoutScreenState extends ConsumerState<BusCheckoutScreen> {
  final _mobileController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _PaymentNetwork _selectedNetwork = _PaymentNetwork.mtn;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from auth profile if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).user;
      if (user != null && user.displayName.isNotEmpty) {
        _nameController.text = user.displayName;
      }
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _generateBookingRef() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return 'HBL-${List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join()}';
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final totalAmount = widget.trip.price * widget.selectedSeats.length;
    final bookingRef = _generateBookingRef();

    // Show simulated Mobile Money USSD prompt modal
    _showMobileMoneyPromptModal(bookingRef, totalAmount);
  }

  void _showMobileMoneyPromptModal(String bookingRef, double totalAmount) {
    final pinController = TextEditingController(text: '1234');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Network Header Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedNetwork.color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone_android_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_selectedNetwork.label} Payment Prompt',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'USSD Push Sent to ${_mobileController.text.trim()}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Prompt details
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedNetwork.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _selectedNetwork.color.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Merchant:',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('${widget.trip.companyName} (Hubble)',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ref No:',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(bookingRef,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('K ${totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _selectedNetwork.color)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Enter 4-Digit Mobile Money PIN to Authorize:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Approve Payment Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() => _isProcessing = true);
                        await _updateSeatsInFirestore();
                        _navigateToReceipt(bookingRef, totalAmount);
                        if (mounted) setState(() => _isProcessing = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedNetwork.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        'Approve & Pay K ${totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateSeatsInFirestore() async {
    // 1. Update local state for immediate offline/local responsiveness
    ref.read(localBusTripsNotifierProvider.notifier).bookSeats(
          widget.trip.id,
          widget.selectedSeats.map((s) => s.id).toList(),
        );

    // 2. Persist to Firestore if available
    try {
      final docRef = FirebaseFirestore.instance.collection('bus_trips').doc(widget.trip.id);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null && data['seats'] != null) {
          final List<dynamic> seatsData = data['seats'];
          final updatedSeatsData = seatsData.map((seatMap) {
            final seatId = seatMap['id'];
            if (widget.selectedSeats.any((s) => s.id == seatId)) {
              return {
                ...seatMap,
                'status': 'booked',
              };
            }
            return seatMap;
          }).toList();

          await docRef.update({'seats': updatedSeatsData});
        }
      }
    } catch (e) {
      debugPrint('Error updating seats in Firestore: $e');
    }
  }

  void _navigateToReceipt(String bookingRef, double totalAmount) {
    if (!mounted || !context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BusReceiptScreen(
          trip: widget.trip,
          selectedSeats: widget.selectedSeats,
          travelDate: widget.travelDate,
          passengerName: _nameController.text.trim(),
          bookingRef: bookingRef,
          totalAmount: totalAmount,
          paymentNetwork: _selectedNetwork.label,
          mobileNumber: _mobileController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary =
        isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary =
        isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    final totalAmount = widget.trip.price * widget.selectedSeats.length;
    final seatIds = widget.selectedSeats.map((s) => s.id).join(', ');
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(widget.travelDate);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Checkout', style: AppTextStyles.h2),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Trip Summary Card ─────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Bus name + route
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(widget.trip.companyColorValue),
                                Color(widget.trip.companyColorValue).withValues(alpha: 0.7)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_bus_filled_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.trip.companyName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '${widget.trip.origin}  →  ${widget.trip.destination}',
                                style: TextStyle(
                                    fontSize: 13, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Details grid
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: dateLabel,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'Departure',
                      value:
                          '${widget.trip.departureTime}  (arrives ${widget.trip.arrivalTime})',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.event_seat_rounded,
                      label: 'Seats',
                      value: seatIds,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.payments_rounded,
                      label: 'Total',
                      value: 'K ${totalAmount.toStringAsFixed(0)}',
                      textPrimary: AppColors.primary,
                      textSecondary: textSecondary,
                      valueBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Passenger Info ────────────────────────────────────────────
              Text(
                'Passenger Details',
                style: AppTextStyles.h3.copyWith(color: textPrimary),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: textPrimary),
                decoration: _inputDecoration(
                  hint: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  cardColor: cardColor,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your name' : null,
              ),

              const SizedBox(height: 24),

              // ── Payment ───────────────────────────────────────────────────
              Text(
                'Mobile Money Payment',
                style: AppTextStyles.h3.copyWith(color: textPrimary),
              ),
              const SizedBox(height: 12),

              // Network selector
              Row(
                children: _PaymentNetwork.values.map((network) {
                  final isSelected = _selectedNetwork == network;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedNetwork = network),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(
                          right: network != _PaymentNetwork.zamtel ? 8 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? network.color.withValues(alpha: 0.15)
                              : cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? network.color
                                : isDark
                                    ? Colors.white12
                                    : Colors.black12,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: network.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              network.label.split(' ').first,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? network.color : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: textPrimary),
                decoration: _inputDecoration(
                  hint: 'Mobile Number (e.g. 0971234567)',
                  icon: Icons.phone_android_rounded,
                  isDark: isDark,
                  cardColor: cardColor,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter your mobile number';
                  }
                  if (v.trim().length < 9) {
                    return 'Enter a valid Zambian number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),
              Text(
                'You will receive a USSD prompt to confirm payment.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            ],
          ),
        ),
      ),

      // ── Bottom confirm button ───────────────────────────────────────────
      bottomSheet: Container(
        color: bgColor,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Pay K ${totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color cardColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: cardColor,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final bool valueBold;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
