import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../marketplace/domain/models/listing_model.dart';
import '../providers/booking_provider.dart';

class BookingCreationScreen extends ConsumerStatefulWidget {
  final UserModel providerUser;
  final ListingModel? prefilledListing;

  const BookingCreationScreen({
    super.key, 
    required this.providerUser,
    this.prefilledListing,
  });

  @override
  ConsumerState<BookingCreationScreen> createState() => _BookingCreationScreenState();
}

class _BookingCreationScreenState extends ConsumerState<BookingCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _quantity = 1;
  bool _isProcessing = false;
  String _errorMessage = '';
  String _paymentMethod = 'escrow';

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;
    
    final isProduct = widget.prefilledListing?.listingType == ListingType.product;
    final isMonthly = widget.prefilledListing?.billingType == BillingType.monthly;

    if (!isProduct && (_selectedDate == null || _selectedTime == null)) {
      setState(() => _errorMessage = 'Please select a date and time.');
      return;
    }

    if (isProduct && _addressController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a delivery address.');
      return;
    }

    final currentUser = ref.read(authStateProvider).user;
    if (currentUser == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    final scheduledFor = isProduct 
        ? DateTime.now().add(const Duration(days: 2)) 
        : DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );

    try {
      final repository = ref.read(bookingRepositoryProvider);
      
      double agreedPrice = widget.providerUser.providerProfile.hourlyRate;
      if (widget.prefilledListing != null) {
        if (isProduct) {
          agreedPrice = widget.prefilledListing!.price * _quantity;
        } else {
          agreedPrice = widget.prefilledListing!.price;
        }
      }

      final jobDesc = isProduct
          ? 'ORDER FOR: ${widget.prefilledListing!.title} (Qty: $_quantity).\nDelivery Address: ${_addressController.text.trim()}\nNotes: ${_descriptionController.text.trim()}'
          : isMonthly
              ? 'MONTHLY SUBSCRIPTION: ${widget.prefilledListing!.title}.\nDetails: ${_descriptionController.text.trim()}'
              : widget.prefilledListing != null
                  ? 'SERVICE BOOKING: ${widget.prefilledListing!.title}.\nDetails: ${_descriptionController.text.trim()}'
                  : _descriptionController.text.trim();

      await repository.createBooking(
        clientId: currentUser.uid,
        clientName: currentUser.displayName,
        providerId: widget.providerUser.uid,
        providerName: widget.providerUser.displayName,
        serviceCategory: widget.prefilledListing?.category ?? widget.providerUser.providerProfile.professionTitle,
        agreedPrice: agreedPrice > 0 ? agreedPrice : 100.0,
        jobDescription: jobDesc,
        scheduledFor: scheduledFor,
        listingId: widget.prefilledListing?.id,
        billingType: widget.prefilledListing?.billingType.toJson() ?? 'fixed',
        quantity: isProduct ? _quantity : 1,
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isProduct ? 'Product order submitted successfully!' : 'Booking request sent successfully!')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = widget.providerUser.providerProfile;
    
    // Check dynamic parameters
    final listing = widget.prefilledListing;
    final isProduct = listing?.listingType == ListingType.product;
    final isMonthly = listing?.billingType == BillingType.monthly;
    
    double unitPrice = listing?.price ?? profile.hourlyRate;
    if (unitPrice <= 0) unitPrice = 100.0;
    
    final totalPrice = isProduct ? unitPrice * _quantity : unitPrice;

    return Scaffold(
      appBar: AppBar(
        title: Text(isProduct ? 'Product Checkout' : 'Request Booking'),
      ),
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isProduct ? 'Purchase from ${widget.providerUser.displayName}' : 'Book ${widget.providerUser.displayName}',
                  style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  listing != null ? '${listing.category} • ${listing.title}' : profile.professionTitle,
                  style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                
                // Dynamic fields depending on listing type
                if (isProduct) ...[
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quantity adjustment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Select Count', style: TextStyle(fontSize: 14)),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    onPressed: (listing == null || _quantity < listing.stockCount) 
                                        ? () => setState(() => _quantity++) 
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              hintText: 'Enter complete street address and phone details...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (isProduct && (value == null || value.trim().isEmpty)) {
                                return 'Please enter delivery address';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMonthly ? 'When do you want to start this service?' : 'When do you need this service?', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectDate(context),
                                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                                  label: Text(
                                    _selectedDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (!isMonthly) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _selectTime(context),
                                    icon: const Icon(Icons.access_time, size: 18),
                                    label: Text(
                                      _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Details & Custom Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          isProduct ? 'Provide custom shipping requests or instructions.' : 'Provide details about the task so the provider can prepare.',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: isProduct 
                                ? 'e.g. Leave packages at the front porch...'
                                : isMonthly 
                                    ? 'Describe scope of maid or monthly service packages...'
                                    : 'e.g. I need help fixing a leaking pipe in the kitchen...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            if (!isProduct && (value == null || value.trim().isEmpty)) {
                              return 'Please describe details';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pricing Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isProduct 
                                  ? 'Unit Price x Qty' 
                                  : isMonthly 
                                      ? 'Monthly Subscription Fee' 
                                      : 'Base Service Price',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              isProduct 
                                  ? 'K ${unitPrice.toStringAsFixed(2)} x $_quantity' 
                                  : 'K ${unitPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                        const Text('Total Agreed Price', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            Text('K ${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Funds will be safely transferred into our secure escrow vault. Funds are only released to the provider when you confirm delivery or successful completion of job.', style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.45)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _paymentMethod,
                          items: const [
                            DropdownMenuItem(value: 'escrow', child: Text('Pay securely via Escrow (Recommended)')),
                            DropdownMenuItem(value: 'cash', child: Text('Pay with Cash directly')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _paymentMethod = val);
                            }
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_paymentMethod == 'cash')
                          const Text(
                            'Warning: Hubble cannot assist with disputes for cash payments. You are taking full responsibility.',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ),
                  
                ElevatedButton(
                  onPressed: _isProcessing ? null : _createBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          isProduct 
                              ? (_paymentMethod == 'escrow' ? 'Authorize Escrow & Purchase' : 'Purchase with Cash') 
                              : (_paymentMethod == 'escrow' ? 'Request Booking & Secure Funds' : 'Request Booking (Cash)'), 
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
