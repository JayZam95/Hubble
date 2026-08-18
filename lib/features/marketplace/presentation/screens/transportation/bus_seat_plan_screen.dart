import 'dart:async';
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

class BusSeatPlanScreen extends ConsumerStatefulWidget {
  final BusTripModel trip;
  final DateTime travelDate;

  const BusSeatPlanScreen({
    super.key,
    required this.trip,
    required this.travelDate,
  });

  @override
  ConsumerState<BusSeatPlanScreen> createState() => _BusSeatPlanScreenState();
}

class _BusSeatPlanScreenState extends ConsumerState<BusSeatPlanScreen> {
  final Set<String> _selectedSeatIds = {};

  void _toggleSeat(SeatModel seat) {
    if (seat.status != SeatStatus.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat ${seat.id} is already booked.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final isNewlySelected = !_selectedSeatIds.contains(seat.id);

    setState(() {
      if (isNewlySelected) {
        _selectedSeatIds.add(seat.id);
      } else {
        _selectedSeatIds.remove(seat.id);
      }
    });

    if (isNewlySelected) {
      _showMobileMoneyConfirmDialog();
    }
  }

  void _proceedToCheckout() {
    if (_selectedSeatIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one seat to proceed.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.warning,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    _showMobileMoneyConfirmDialog();
  }

  void _showMobileMoneyConfirmDialog() {
    final trips = ref.read(busTripsStreamProvider).value;
    final currentTrip = trips?.firstWhere((t) => t.id == widget.trip.id, orElse: () => widget.trip) ?? widget.trip;
    final selectedSeatsList = currentTrip.seats
        .where((s) => _selectedSeatIds.contains(s.id))
        .toList();

    if (selectedSeatsList.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAmount = currentTrip.price * selectedSeatsList.length;
    final user = ref.read(authStateProvider).user;

    final nameController = TextEditingController(text: user?.displayName ?? '');
    final mobileController = TextEditingController(text: '0971234567');
    _PaymentNetwork selectedNetwork = _PaymentNetwork.mtn;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.phone_android_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Confirm Seat Payment',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Mobile Money Checkout',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Selected Seat summary card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${widget.trip.companyName} (${widget.trip.busClass})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${widget.trip.origin} → ${widget.trip.destination}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Seat${selectedSeatsList.length > 1 ? "s" : ""}: ${_selectedSeatIds.join(", ")}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'K ${totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Passenger Name
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Passenger Name',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter passenger name' : null,
                    ),

                    const SizedBox(height: 14),

                    // Network selector
                    Row(
                      children: _PaymentNetwork.values.map((net) {
                        final isSel = selectedNetwork == net;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedNetwork = net),
                            child: Container(
                              margin: EdgeInsets.only(right: net != _PaymentNetwork.zamtel ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel ? net.color.withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? net.color : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: net.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    net.label.split(' ').first,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? net.color : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // Mobile number input
                    TextFormField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Mobile Money Number',
                        prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => v == null || v.trim().length < 9 ? 'Enter valid Zambian mobile number' : null,
                    ),

                    const SizedBox(height: 20),

                    // Confirm & Pay button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(modalCtx);
                          _executeMobileMoneyPayment(
                            selectedSeatsList: selectedSeatsList,
                            passengerName: nameController.text.trim(),
                            mobileNumber: mobileController.text.trim(),
                            network: selectedNetwork,
                            totalAmount: totalAmount,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedNetwork.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(
                          'Confirm & Pay K ${totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _executeMobileMoneyPayment({
    required List<SeatModel> selectedSeatsList,
    required String passengerName,
    required String mobileNumber,
    required _PaymentNetwork network,
    required double totalAmount,
  }) {
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final bookingRef = 'HBL-${List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join()}';

    final pinController = TextEditingController(text: '1234');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (pinCtx) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: network.color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${network.label} PIN Verification',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text('USSD Push Sent to $mobileNumber', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Enter 4-Digit Mobile Money PIN for K ${totalAmount.toStringAsFixed(0)}:',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(pinCtx);

                    // 1. Immediately update local Riverpod state
                    ref.read(localBusTripsNotifierProvider.notifier).bookSeats(
                      widget.trip.id,
                      selectedSeatsList.map((s) => s.id).toList(),
                    );

                    // 2. Perform Firestore persistence asynchronously in background
                    final user = ref.read(authStateProvider).user;
                    final uid = user?.uid ?? 'guest';

                    unawaited(
                      Future(() async {
                        try {
                          final docRef = FirebaseFirestore.instance.collection('bus_trips').doc(widget.trip.id);
                          final docSnap = await docRef.get();
                          if (docSnap.exists) {
                            final data = docSnap.data();
                            if (data != null && data['seats'] != null) {
                              final List<dynamic> seatsData = data['seats'];
                              final updatedSeatsData = seatsData.map((seatMap) {
                                final seatId = seatMap['id'];
                                if (selectedSeatsList.any((s) => s.id == seatId)) {
                                  return {...seatMap, 'status': 'booked'};
                                }
                                return seatMap;
                              }).toList();
                              await docRef.update({'seats': updatedSeatsData});
                            }
                          } else {
                            final updatedTrip = widget.trip.copyWith(
                              seats: widget.trip.seats.map((s) {
                                if (selectedSeatsList.any((sel) => sel.id == s.id)) {
                                  return s.copyWith(status: SeatStatus.booked);
                                }
                                return s;
                              }).toList(),
                            );
                            await docRef.set(updatedTrip.toMap());
                          }

                          await FirebaseFirestore.instance.collection('bus_bookings').doc(bookingRef).set({
                            'id': bookingRef,
                            'bookingRef': bookingRef,
                            'tripId': widget.trip.id,
                            'companyName': widget.trip.companyName,
                            'busClass': widget.trip.busClass,
                            'origin': widget.trip.origin,
                            'destination': widget.trip.destination,
                            'departureTime': widget.trip.departureTime.toIso8601String(),
                            'arrivalTime': widget.trip.arrivalTime.toIso8601String(),
                            'travelDate': widget.travelDate.toIso8601String(),
                            'seats': selectedSeatsList.map((s) => s.id).toList(),
                            'passengerName': passengerName,
                            'mobileNumber': mobileNumber,
                            'paymentNetwork': network.label,
                            'totalAmount': totalAmount,
                            'userId': uid,
                            'clientId': uid,
                            'createdAt': FieldValue.serverTimestamp(),
                            'status': 'CONFIRMED',
                          });

                          await FirebaseFirestore.instance.collection('bookings').doc(bookingRef).set({
                            'id': bookingRef,
                            'title': '${widget.trip.companyName} (${widget.trip.origin} → ${widget.trip.destination})',
                            'category': 'Transport / Intercity Bus',
                            'clientId': uid,
                            'providerId': widget.trip.companyName,
                            'totalPrice': totalAmount,
                            'currency': 'ZMW',
                            'status': 'ACCEPTED',
                            'createdAt': DateTime.now().toIso8601String(),
                            'scheduledDate': widget.travelDate.toIso8601String(),
                            'busSeats': selectedSeatsList.map((s) => s.id).toList(),
                            'passengerName': passengerName,
                            'paymentNetwork': network.label,
                          });
                        } catch (e) {
                          debugPrint('Error writing bus booking to firestore: $e');
                        }
                      }),
                    );

                    // 3. Immediately transition to BusReceiptScreen!
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusReceiptScreen(
                            trip: widget.trip,
                            selectedSeats: selectedSeatsList,
                            travelDate: widget.travelDate,
                            passengerName: passengerName,
                            bookingRef: bookingRef,
                            totalAmount: totalAmount,
                            paymentNetwork: network.label,
                            mobileNumber: mobileNumber,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: network.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text('Approve & Pay K ${totalAmount.toStringAsFixed(0)}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textSecondary =
        isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    final tripsAsync = ref.watch(busTripsStreamProvider);
    final currentTrip = tripsAsync.when(
      data: (trips) => trips.firstWhere((t) => t.id == widget.trip.id, orElse: () => widget.trip),
      loading: () => widget.trip,
      error: (err, stack) => widget.trip,
    );

    final seats = currentTrip.seats;

    // Automatically remove any seat if it becomes booked in real time by another user
    for (final s in seats) {
      if (s.status == SeatStatus.booked && _selectedSeatIds.contains(s.id)) {
        _selectedSeatIds.remove(s.id);
      }
    }

    final rowCount = (seats.length / 4).ceil();
    final gridItemCount = rowCount * 5;
    final totalPrice = currentTrip.price * _selectedSeatIds.length;
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(widget.travelDate);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              '${widget.trip.origin} → ${widget.trip.destination}',
              style: AppTextStyles.h2,
            ),
            Text(
              '${widget.trip.companyName}  ·  $dateLabel',
              style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Legend Bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _LegendItem(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderColor: AppColors.primary.withValues(alpha: 0.3),
                    label: 'Available',
                  ),
                  _LegendItem(
                    color: AppColors.primary,
                    borderColor: AppColors.primary,
                    label: 'Selected',
                    textColor: Colors.white,
                  ),
                  _LegendItem(
                    color: isDark
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.error.withValues(alpha: 0.08),
                    borderColor: AppColors.error.withValues(alpha: 0.3),
                    label: 'Booked',
                  ),
                ],
              ),
            ),
          ),

          // ── BUS BLUEPRINT BODY (Frame & Layout) ──────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              child: Column(
                children: [
                  // Bus Outer Shell Blueprint Frame
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(48), // Curved Windscreen Top
                        bottom: Radius.circular(24),
                      ),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ── Front Windscreen & Driver Cabin Section ──────────
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(45),
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Windscreen contour bar
                              Container(
                                width: 80,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Driver Seat & Steering Wheel
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.black.withValues(alpha: 0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.sports_score_rounded,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'DRIVER',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          Text(
                                            'Cabin Area',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Direction Arrow Indicator
                                  Row(
                                    children: [
                                      const Icon(Icons.arrow_upward_rounded,
                                          size: 14, color: AppColors.primary),
                                      const SizedBox(width: 2),
                                      Text(
                                        'FRONT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Main Entrance Door
                                  Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'ENTRANCE',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                              color: textSecondary,
                                            ),
                                          ),
                                          Text(
                                            'Door Pass',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.login_rounded,
                                          size: 18,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── Window Labels Bar ─────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.window_rounded,
                                      size: 12, color: textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'LEFT WINDOW',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'AISLE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'RIGHT WINDOW',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.window_rounded,
                                      size: 12, color: textSecondary),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── 2x2 Seat Layout Grid ──────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              childAspectRatio: 0.88,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: gridItemCount,
                            itemBuilder: (ctx, index) {
                              final col = index % 5;

                              // Column 2 = Center Aisle Walkway
                              if (col == 2) {
                                final isMiddleRow = (index ~/ 5) == (rowCount ~/ 2);
                                return Center(
                                  child: isMiddleRow
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.arrow_upward_rounded,
                                              size: 16,
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ],
                                        )
                                      : Container(
                                          width: 1,
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.black.withValues(alpha: 0.08),
                                        ),
                                );
                              }

                              // Seat index mapping
                              final row = index ~/ 5;
                              final seatCol = col > 2 ? col - 1 : col;
                              final seatIndex = row * 4 + seatCol;

                              if (seatIndex >= seats.length) {
                                return const SizedBox();
                              }

                              final seat = seats[seatIndex];
                              final isSelected = _selectedSeatIds.contains(seat.id);

                              Color seatBgColor;
                              Color borderColor;
                              Color textColor;
                              IconData iconData;

                              if (seat.status != SeatStatus.available) {
                                seatBgColor = isDark
                                    ? AppColors.error.withValues(alpha: 0.15)
                                    : AppColors.error.withValues(alpha: 0.08);
                                borderColor = AppColors.error.withValues(alpha: 0.3);
                                textColor = AppColors.error.withValues(alpha: 0.5);
                                iconData = Icons.lock_outline_rounded;
                              } else if (isSelected) {
                                seatBgColor = AppColors.primary;
                                borderColor = AppColors.primary;
                                textColor = Colors.white;
                                iconData = Icons.check_circle_rounded;
                              } else {
                                seatBgColor = isDark
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : AppColors.primary.withValues(alpha: 0.05);
                                borderColor = AppColors.primary.withValues(alpha: 0.25);
                                textColor = AppColors.primary;
                                iconData = Icons.event_seat_rounded;
                              }

                              return GestureDetector(
                                onTap: () => _toggleSeat(seat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  decoration: BoxDecoration(
                                    color: seatBgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor, width: 1.5),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        iconData,
                                        size: 16,
                                        color: textColor,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        seat.id,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // ── Rear Luggage / Engine Compartment ───────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(22),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.work_outline_rounded,
                                  size: 14, color: textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'Rear Luggage & Engine Section',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Sheet (Seat Summary & Checkout CTA) ───────────────────────
      bottomSheet: _selectedSeatIds.isEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap any available seat above to select your preferred spot.',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Price info
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedSeatIds.length} seat${_selectedSeatIds.length > 1 ? 's' : ''} selected (${_selectedSeatIds.join(", ")})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'K ${totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Checkout Button
                    ElevatedButton.icon(
                      onPressed: _proceedToCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String label;
  final Color? textColor;

  const _LegendItem({
    required this.color,
    required this.borderColor,
    required this.label,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor ??
                (isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary),
          ),
        ),
      ],
    );
  }
}

