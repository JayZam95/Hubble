import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../domain/models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../../../reviews/presentation/screens/review_submission_screen.dart';
import '../../../wallet/presentation/providers/payment_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'live_tracking_screen.dart';
import '../../../../core/services/pdf_invoice_service.dart';


class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _isProcessing = false;
  String _errorMessage = '';

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.PENDING:
        return Colors.orange;
      case BookingStatus.ACCEPTED:
        return Colors.blue;
      case BookingStatus.IN_PROGRESS:
        return Colors.purple;
      case BookingStatus.COMPLETED:
        return Colors.green;
      case BookingStatus.CANCELLED:
        return Colors.red;
      case BookingStatus.DISPUTED:
        return Colors.redAccent;
    }
  }

  Future<void> _updateStatus(BookingModel booking, BookingStatus newStatus) async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      final repository = ref.read(bookingRepositoryProvider);
      await repository.updateBookingStatus(
        bookingId: booking.bookingId,
        userId: user.uid,
        newStatus: newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking marked as ${newStatus.displayName}!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (newStatus == BookingStatus.COMPLETED) {
          final isClient = booking.clientId == user.uid;
          final revieweeId = isClient ? booking.providerId : booking.clientId;
          final revieweeName = isClient ? booking.providerName : booking.clientName;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewSubmissionScreen(
                revieweeId: revieweeId,
                revieweeName: revieweeName,
                jobId: booking.bookingId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _raiseDispute(BookingModel booking, String currentUserId) async {
    final reasonController = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Raise Dispute'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: 'Enter reason for dispute',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Navigator.pop(context, reasonController.text.trim());
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      setState(() {
        _isProcessing = true;
        _errorMessage = '';
      });

      try {
        await FirebaseFirestore.instance.collection('disputes').add({
          'bookingId': booking.bookingId,
          'reason': reason,
          'raisedBy': currentUserId,
          'status': 'OPEN',
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        final repository = ref.read(bookingRepositoryProvider);
        await repository.updateBookingStatus(
          bookingId: booking.bookingId,
          userId: currentUserId,
          newStatus: BookingStatus.DISPUTED,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dispute raised successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString().replaceAll('Exception: ', '');
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    final clientAsync = ref.watch(clientBookingsStreamProvider);
    final providerAsync = ref.watch(providerBookingsStreamProvider);

    final allBookings = [...(clientAsync.value ?? []), ...(providerAsync.value ?? [])];
    final bookingIndex = allBookings.indexWhere((b) => b.bookingId == widget.bookingId);

    if (bookingIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final booking = allBookings[bookingIndex];

    final isClient = booking.clientId == user.uid;
    final statusColor = _getStatusColor(booking.status);
    final dateString = DateFormat('EEEE, MMM dd, yyyy').format(booking.timestamps.scheduledFor);
    final timeString = DateFormat('h:mm a').format(booking.timestamps.scheduledFor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Escrow Checkout'),
        actions: [
          IconButton(
            tooltip: 'Download PDF Invoice',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final pdfBytes = await PdfInvoiceService.generateBookingInvoice(booking);
              if (context.mounted) {
                PdfInvoiceService.previewPdf(context, pdfBytes, 'Hubble_Booking_Invoice_${booking.bookingId}.pdf');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- SECTION 1: HEADER SUMMARY ---
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                booking.serviceCategory,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  booking.status.displayName,
                                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isClient ? 'Service Provider: ${booking.providerName}' : 'Client Name: ${booking.clientName}',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- SECTION 2: TIMING & DESCRIPTION ---
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Scheduled For', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(dateString, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(timeString, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const Divider(height: 32),
                          const Text('Job Description', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            booking.jobDescription,
                            style: const TextStyle(fontSize: 15, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- SECTION 3: ESCROW FINANCIAL BREAKDOWN ---
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.financials.paymentMethod == 'escrow' ? 'Payment Details (Held in Escrow)' : 'Payment Details (Cash)', 
                            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Agreed Price', style: TextStyle(fontSize: 15)),
                              Text('K ${booking.financials.agreedPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Platform Fee (10%)', style: TextStyle(fontSize: 15)),
                              Text('K ${booking.financials.platformFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Provider Payout', style: TextStyle(fontSize: 15)),
                              Text('K ${booking.financials.providerPayout.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                booking.financials.paymentMethod == 'escrow' ? 'Total Held in Escrow' : 'Total Cash Payment', 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                              ),
                              Text(
                                'K ${booking.financials.agreedPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- SECTION 4: STATE ACTION BUTTONS ---
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    if (_errorMessage.isNotEmpty) ...[
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Client Action: Cancel Job
                    if (isClient && booking.status == BookingStatus.PENDING)
                      ElevatedButton.icon(
                        key: const Key('booking_action_cancel'),
                        onPressed: () => _updateStatus(booking, BookingStatus.CANCELLED),
                        icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                        label: const Text('Cancel Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      
                    // Client Action: Track Live & Raise Dispute
                    if (isClient && (booking.status == BookingStatus.ACCEPTED || booking.status == BookingStatus.IN_PROGRESS)) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveTrackingScreen(booking: booking),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map, color: Colors.white),
                        label: const Text('Track Provider Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('booking_action_dispute'),
                        onPressed: () => _raiseDispute(booking, user.uid),
                        icon: const Icon(Icons.gavel, color: Colors.redAccent),
                        label: const Text('Raise Dispute', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],

                    // Provider Actions
                    if (user.uid == booking.providerId && booking.status == BookingStatus.PENDING) ...[
                      ElevatedButton.icon(
                        key: const Key('booking_action_accept'),
                        onPressed: () => _updateStatus(booking, BookingStatus.ACCEPTED),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: const Text('Accept Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('booking_action_decline'),
                        onPressed: () => _updateStatus(booking, BookingStatus.CANCELLED),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Decline Request', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],

                    if (user.uid == booking.providerId && booking.status == BookingStatus.ACCEPTED)
                      ElevatedButton.icon(
                        key: const Key('booking_action_start'),
                        onPressed: () => _updateStatus(booking, BookingStatus.IN_PROGRESS),
                        icon: const Icon(Icons.play_circle_outline, color: Colors.white),
                        label: const Text('Start Work', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
 
                    if (user.uid == booking.providerId && booking.status == BookingStatus.IN_PROGRESS)
                      ElevatedButton.icon(
                        key: const Key('booking_action_complete'),
                        onPressed: () => _updateStatus(booking, BookingStatus.COMPLETED),
                        label: const Text('Job Finished', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                    // Client Action: Release Funds, Dispute, and Review
                    if (isClient && booking.status == BookingStatus.COMPLETED) ...[
                      if (booking.financials.paymentMethod == 'escrow') ...[
                        ElevatedButton.icon(
                          key: const Key('booking_action_release_funds'),
                          onPressed: () async {
                            setState(() {
                              _isProcessing = true;
                              _errorMessage = '';
                            });
                            try {
                              await ref.read(paymentControllerProvider.notifier).releaseEscrow(
                                booking.bookingId,
                                booking.providerId,
                                booking.financials.providerPayout,
                                booking.clientId,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Funds released successfully!')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() => _errorMessage = e.toString());
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isProcessing = false);
                              }
                            }
                          },
                          icon: const Icon(Icons.monetization_on, color: Colors.white),
                          label: const Text('Release Funds', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const Key('booking_action_dispute_completed'),
                          onPressed: () => _raiseDispute(booking, user.uid),
                          icon: const Icon(Icons.gavel, color: Colors.redAccent),
                          label: const Text('Dispute', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('This booking was paid in cash.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ElevatedButton.icon(
                        key: const Key('booking_action_review'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReviewSubmissionScreen(
                                revieweeId: booking.providerId,
                                revieweeName: booking.providerName,
                                jobId: booking.bookingId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.star_rate, color: Colors.white),
                        label: const Text('Leave a Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
