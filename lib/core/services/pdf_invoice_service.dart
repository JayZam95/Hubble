import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext, MaterialPageRoute, Scaffold, AppBar, Text, Brightness, Theme, IconButton, Icon, Icons, Colors, Color, TextStyle, FontWeight, StatelessWidget, Widget, Navigator;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/bookings/domain/models/booking_model.dart';
import '../../features/marketplace/domain/models/bus_trip_model.dart';
import '../../features/marketplace/domain/models/cart_model.dart';

class PdfInvoiceService {
  /// Generate a PDF receipt for a service booking
  static Future<Uint8List> generateBookingInvoice(BookingModel booking) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
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
                        'HUBBLE PLATFORM',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.deepPurple700,
                        ),
                      ),
                      pw.Text('Official Digital Escrow Invoice', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('Lusaka, Zambia • support@hubble.zm', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.deepPurple50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.deepPurple200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE REF', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple900)),
                        pw.Text('#${booking.bookingId}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: ${dateFormat.format(booking.timestamps.requestedAt)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 15),

              // Parties Information
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CLIENT / BILL TO:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text(booking.clientName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Customer ID: ${booking.clientId}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('VERIFIED PROVIDER:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text(booking.providerName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Category: ${booking.serviceCategory}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Status Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: booking.financials.isHeldInEscrow ? PdfColors.green50 : PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'STATUS: ${booking.status.displayName.toUpperCase()}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.green900),
                    ),
                    pw.Text(
                      booking.financials.isHeldInEscrow ? '🔒 Held in Escrow Protection' : 'Direct Payment',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Itemized Table
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple700),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                headers: ['Description / Service', 'Schedule Date', 'Qty', 'Amount (ZMW)'],
                data: [
                  [
                    booking.jobDescription.isNotEmpty ? booking.jobDescription : 'Service Fee (${booking.serviceCategory})',
                    dateFormat.format(booking.timestamps.scheduledFor),
                    '${booking.quantity}',
                    booking.financials.agreedPrice.toStringAsFixed(2),
                  ],
                  [
                    'Hubble Buyer Protection & Escrow Fee (5%)',
                    '—',
                    '1',
                    booking.financials.platformFee.toStringAsFixed(2),
                  ],
                ],
              ),
              pw.SizedBox(height: 20),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('ZMW ${booking.financials.agreedPrice.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Platform Fee:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('ZMW ${booking.financials.platformFee.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Divider(color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Paid:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                            pw.Text(
                              'ZMW ${(booking.financials.agreedPrice + booking.financials.platformFee).toStringAsFixed(2)}',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.deepPurple800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Thank you for choosing Hubble!', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Generated electronically by Hubble App', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate a PDF receipt for physical marketplace cart purchases
  static Future<Uint8List> generateCartInvoice({
    required String orderId,
    required List<CartItem> items,
    required double totalPrice,
    required String customerName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final deliveryFee = 35.0; // Standard local delivery fee in ZMW

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
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
                        'HUBBLE MARKETPLACE',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.Text('Order Purchase Receipt', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('RECEIPT ID', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text('#$orderId', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              pw.Text('CUSTOMER INFORMATION', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.Text(customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 15),

              // Items Table
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                headers: ['Item Name', 'Category', 'Unit Price', 'Qty', 'Subtotal (ZMW)'],
                data: items.map((item) {
                  return [
                    item.listing.title,
                    item.listing.category,
                    'ZMW ${item.listing.price.toStringAsFixed(2)}',
                    '${item.quantity}',
                    'ZMW ${(item.listing.price * item.quantity).toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 15),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Cart Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('ZMW ${totalPrice.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Express Delivery Fee:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('ZMW ${deliveryFee.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Divider(color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Grand Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                            pw.Text(
                              'ZMW ${(totalPrice + deliveryFee).toStringAsFixed(2)}',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.Center(
                child: pw.Text('Hubble E-Commerce Zambia • Track orders in app', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate a PDF Bus Ticket Boarding Pass
  static Future<Uint8List> generateBusTicketReceipt({
    required BusTripModel trip,
    required String passengerName,
    required List<String> seatNumbers,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('EEE, dd MMM yyyy • HH:mm');
    final totalFare = trip.price * (seatNumbers.isNotEmpty ? seatNumbers.length : 1);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Ticket Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal700,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INTER-CITY BUS BOARDING PASS', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 16)),
                        pw.Text(trip.companyName, style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        trip.busClass.toUpperCase(),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal900, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Route Info Card
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.teal200, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ORIGIN CITY', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                        pw.Text(trip.origin, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.Text(dateFormat.format(trip.departureTime), style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Text('➔ ➔ ➔', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('DESTINATION CITY', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                        pw.Text(trip.destination, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.Text(dateFormat.format(trip.arrivalTime), style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Passenger Details
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                cellPadding: const pw.EdgeInsets.all(10),
                headers: ['Passenger Name', 'Assigned Seats', 'Ticket Class', 'Total Fare'],
                data: [
                  [
                    passengerName,
                    seatNumbers.isNotEmpty ? seatNumbers.join(', ') : 'Seat 12',
                    trip.busClass,
                    'ZMW ${totalFare.toStringAsFixed(2)}',
                  ],
                ],
              ),
              pw.SizedBox(height: 30),

              // Barcode / Ticket Code Section
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: 'HUBBLE-BUS-${trip.id}-${DateTime.now().millisecondsSinceEpoch}',
                      width: 250,
                      height: 60,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Present this digital PDF ticket barcode at the terminal station for boarding.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.Center(
                child: pw.Text('Hubble Travel Services Zambia • Verified Operator', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Launch PDF preview / print / share dialog screen
  static void previewPdf(BuildContext context, Uint8List pdfBytes, String filename) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(pdfBytes: pdfBytes, filename: filename),
      ),
    );
  }
}

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String filename;

  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          filename,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share Receipt',
            icon: const Icon(Icons.share),
            onPressed: () {
              Printing.sharePdf(bytes: pdfBytes, filename: filename);
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfBytes,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        maxPageWidth: 700,
      ),
    );
  }
}
