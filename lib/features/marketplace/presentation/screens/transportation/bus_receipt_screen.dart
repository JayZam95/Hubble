import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../domain/models/bus_trip_model.dart';

class BusReceiptScreen extends StatefulWidget {
  final BusTripModel trip;
  final List<SeatModel> selectedSeats;
  final DateTime travelDate;
  final String passengerName;
  final String bookingRef;
  final double totalAmount;
  final String paymentNetwork;
  final String mobileNumber;

  const BusReceiptScreen({
    super.key,
    required this.trip,
    required this.selectedSeats,
    required this.travelDate,
    required this.passengerName,
    required this.bookingRef,
    required this.totalAmount,
    required this.paymentNetwork,
    required this.mobileNumber,
  });

  @override
  State<BusReceiptScreen> createState() => _BusReceiptScreenState();
}

class _BusReceiptScreenState extends State<BusReceiptScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScale;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkScale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _downloadPdfTicket() async {
    final pdf = pw.Document();
    final seatIds = widget.selectedSeats.map((SeatModel s) => s.id).join(', ');
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(widget.travelDate);
    final depTime = DateFormat('HH:mm').format(widget.trip.departureTime);
    final arrTime = DateFormat('HH:mm').format(widget.trip.arrivalTime);
    final issuedAt = DateFormat('d MMM yyyy · HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey800, width: 2),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'HUBBLE INTERCITY BUS E-TICKET',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          widget.trip.companyName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green700,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        'PAID & CONFIRMED',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 12),

                // Booking Reference
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('BOOKING REFERENCE:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      widget.bookingRef,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Route Container
                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('DEPARTURE',
                              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.Text(widget.trip.origin,
                              style: pw.TextStyle(
                                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.Text(depTime, style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.Text('--->',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Column(
                        children: [
                          pw.Text('DESTINATION',
                              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          pw.Text(widget.trip.destination,
                              style: pw.TextStyle(
                                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.Text(arrTime, style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),

                // Details Grid Table
                pw.TableHelper.fromTextArray(
                  headers: ['Passenger', 'Travel Date', 'Seats', 'Bus Class'],
                  data: [
                    [
                      widget.passengerName,
                      dateLabel,
                      seatIds,
                      widget.trip.busClass,
                    ]
                  ],
                  headerStyle:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  cellHeight: 30,
                ),
                pw.SizedBox(height: 16),

                // Payment Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Payment Method:'),
                          pw.Text('${widget.paymentNetwork} (${widget.mobileNumber})'),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Fare Paid:',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                            'ZMW ${widget.totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // QR Code
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data:
                            'HUBBLE-TICKET:${widget.bookingRef}:${widget.passengerName}:$seatIds',
                        width: 90,
                        height: 90,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Present QR Code or Booking Reference at Bus Terminal for Boarding Pass',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Footer
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Issued: $issuedAt',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.Text('Hubble SuperApp Zambia',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Hubble_Bus_Ticket_${widget.bookingRef}.pdf',
    );
  }

  void _shareTicket() {
    final seatIds = widget.selectedSeats.map((SeatModel s) => s.id).join(', ');
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(widget.travelDate);

    final text = '''
🚌 HUBBLE BUS E-TICKET
──────────────────────
Booking Ref: ${widget.bookingRef}
Passenger  : ${widget.passengerName}
Bus        : ${widget.trip.companyName}
Route      : ${widget.trip.origin} → ${widget.trip.destination}
Date       : $dateLabel
Departure  : ${widget.trip.departureTime}  |  Arrives ${widget.trip.arrivalTime}
Seats      : $seatIds
──────────────────────
Total Paid : K ${widget.totalAmount.toStringAsFixed(0)}
Network    : ${widget.paymentNetwork}
──────────────────────
Present this ticket at the bus terminal.
Powered by Hubble 🌐
''';
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'My Hubble Bus Ticket — ${widget.bookingRef}',
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
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

    final seatIds = widget.selectedSeats.map((SeatModel s) => s.id).join(', ');
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(widget.travelDate);
    final issuedAt = DateFormat('d MMM yyyy · HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Booking Confirmed',
          style: AppTextStyles.h2.copyWith(color: textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
        child: Column(
          children: [
            // ── Success animation ─────────────────────────────────────────
            const SizedBox(height: 16),
            ScaleTransition(
              scale: _checkScale,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fadeIn,
              child: Column(
                children: [
                  Text(
                    'Payment Successful!',
                    style: AppTextStyles.h1.copyWith(
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your electronic ticket is ready. Safe travels! 🎉',
                    style: TextStyle(fontSize: 14, color: textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Ticket card ───────────────────────────────────────────────
            FadeTransition(
              opacity: _fadeIn,
              child: _TicketCard(
                isDark: isDark,
                cardColor: cardColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                trip: widget.trip,
                bookingRef: widget.bookingRef,
                passengerName: widget.passengerName,
                dateLabel: dateLabel,
                seatIds: seatIds,
                totalAmount: widget.totalAmount,
                paymentNetwork: widget.paymentNetwork,
                mobileNumber: widget.mobileNumber,
                issuedAt: issuedAt,
              ),
            ),

            const SizedBox(height: 16),

            // ── Info note ─────────────────────────────────────────────────
            FadeTransition(
              opacity: _fadeIn,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Show this e-ticket or present your booking reference at Lusaka Intercity Bus Terminus (LITBS) before boarding.',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Action buttons (Download PDF, Share, Done) ─────────────────────
      bottomSheet: Container(
        color: bgColor,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Download PDF Ticket CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _downloadPdfTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  label: const Text(
                    'Download PDF Receipt / Ticket',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Share ticket
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareTicket,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'Share Text',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Done
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _goHome(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ticket card widget — styled like a physical bus ticket
// ---------------------------------------------------------------------------
class _TicketCard extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final BusTripModel trip;
  final String bookingRef;
  final String passengerName;
  final String dateLabel;
  final String seatIds;
  final double totalAmount;
  final String paymentNetwork;
  final String mobileNumber;
  final String issuedAt;

  const _TicketCard({
    required this.isDark,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.trip,
    required this.bookingRef,
    required this.passengerName,
    required this.dateLabel,
    required this.seatIds,
    required this.totalAmount,
    required this.paymentNetwork,
    required this.mobileNumber,
    required this.issuedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header strip ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(trip.companyColorValue),
                  Color(trip.companyColorValue).withValues(alpha: 0.7)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_bus_filled_rounded,
                        color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      trip.companyName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        trip.busClass.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Route display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          trip.origin,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(trip.departureTime),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white54,
                        size: 28,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          trip.destination,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(trip.arrivalTime),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Ticket tear line ─────────────────────────────────────────────
          _TearLine(isDark: isDark, cardColor: cardColor),

          // ── Ticket body ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _TicketField(
                  label: 'BOOKING REFERENCE',
                  value: bookingRef,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  valueStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TicketField(
                        label: 'PASSENGER',
                        value: passengerName,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                    Expanded(
                      child: _TicketField(
                        label: 'DATE',
                        value: dateLabel,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        align: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TicketField(
                        label: 'SEATS',
                        value: seatIds,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                    Expanded(
                      child: _TicketField(
                        label: 'AMOUNT PAID',
                        value: 'K ${totalAmount.toStringAsFixed(0)}',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        align: TextAlign.right,
                        valueStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TicketField(
                        label: 'PAYMENT',
                        value: paymentNetwork,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                    Expanded(
                      child: _TicketField(
                        label: 'MOBILE',
                        value: mobileNumber,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        align: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── QR placeholder ────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                // QR placeholder
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: 49,
                        itemBuilder: (_, i) {
                          // Deterministic fake QR pattern
                          final fill = (i * 13 + 7) % 3 == 0;
                          return Container(
                            decoration: BoxDecoration(
                              color: fill
                                  ? (isDark ? Colors.white70 : Colors.black87)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan at Terminal',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Show this QR code or your booking reference to the terminal agent before boarding.',
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Center(
              child: Text(
                'Issued $issuedAt  ·  Powered by Hubble',
                style: TextStyle(fontSize: 10, color: textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tear line (dashed) separator
// ---------------------------------------------------------------------------
class _TearLine extends StatelessWidget {
  final bool isDark;
  final Color cardColor;

  const _TearLine({required this.isDark, required this.cardColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          // Left notch
          Transform.translate(
            offset: const Offset(-12, 0),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDark : AppColors.bgLight,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Dashes
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const dashWidth = 8.0;
                const dashSpace = 4.0;
                final count =
                    (constraints.maxWidth / (dashWidth + dashSpace)).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    count,
                    (_) => Container(
                      width: dashWidth,
                      height: 1.5,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                );
              },
            ),
          ),
          // Right notch
          Transform.translate(
            offset: const Offset(12, 0),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDark : AppColors.bgLight,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable ticket field
// ---------------------------------------------------------------------------
class _TicketField extends StatelessWidget {
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final TextAlign align;
  final TextStyle? valueStyle;

  const _TicketField({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    this.align = TextAlign.left,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: align,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: align,
          style: valueStyle ??
              TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
        ),
      ],
    );
  }
}
