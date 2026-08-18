import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/booking_model.dart';
import '../providers/booking_provider.dart';
import 'booking_detail_screen.dart';

class ProviderCalendarScreen extends ConsumerStatefulWidget {
  const ProviderCalendarScreen({super.key});

  @override
  ConsumerState<ProviderCalendarScreen> createState() => _ProviderCalendarScreenState();
}

class _ProviderCalendarScreenState extends ConsumerState<ProviderCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<BookingModel> _getBookingsForDay(DateTime day, List<BookingModel> allBookings) {
    return allBookings.where((booking) {
      final bookingDate = booking.timestamps.scheduledFor;
      return isSameDay(bookingDate, day);
    }).toList();
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry? padding, double borderRadius = 16}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(providerBookingsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Booking Calendar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background blobs for glassmorphism effect
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.2),
              ),
            ),
          ),
          SafeArea(
            child: bookingsAsync.when(
              data: (allBookings) {
                final selectedDayBookings = _getBookingsForDay(_selectedDay ?? _focusedDay, allBookings);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildGlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: TableCalendar<BookingModel>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            if (!isSameDay(_selectedDay, selectedDay)) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            }
                          },
                          onFormatChanged: (format) {
                            if (_calendarFormat != format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            }
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          eventLoader: (day) => _getBookingsForDay(day, allBookings),
                          calendarStyle: CalendarStyle(
                            defaultTextStyle: const TextStyle(color: Colors.white),
                            weekendTextStyle: const TextStyle(color: Colors.white70),
                            outsideTextStyle: const TextStyle(color: Colors.white38),
                            selectedDecoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          headerStyle: const HeaderStyle(
                            titleTextStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            formatButtonTextStyle: TextStyle(color: Colors.white),
                            formatButtonDecoration: BoxDecoration(
                              border: Border.fromBorderSide(BorderSide(color: Colors.white)),
                              borderRadius: BorderRadius.all(Radius.circular(12.0)),
                            ),
                            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(color: Colors.white70),
                            weekendStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Schedule for ${DateFormat.yMMMd().format(_selectedDay ?? _focusedDay)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: selectedDayBookings.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No bookings for this day.',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: selectedDayBookings.length,
                                      itemBuilder: (context, index) {
                                        final booking = selectedDayBookings[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => BookingDetailScreen(bookingId: booking.bookingId),
                                                ),
                                              );
                                            },
                                            child: _buildGlassContainer(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withValues(alpha: 0.2),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.event, color: AppColors.primary),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          booking.serviceCategory,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'Client: ${booking.clientName}',
                                                          style: TextStyle(
                                                            color: Colors.white.withValues(alpha: 0.8),
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.access_time, size: 14, color: Colors.white70),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              DateFormat.jm().format(booking.timestamps.scheduledFor),
                                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: _getStatusColor(booking.status).withValues(alpha: 0.2),
                                                                borderRadius: BorderRadius.circular(12),
                                                                border: Border.all(
                                                                  color: _getStatusColor(booking.status).withValues(alpha: 0.5),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                booking.status.displayName,
                                                                style: TextStyle(
                                                                  color: _getStatusColor(booking.status),
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Icon(Icons.chevron_right, color: Colors.white54),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (error, stack) => Center(
                child: Text('Error loading calendar: $error', style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.PENDING:
        return Colors.orange;
      case BookingStatus.ACCEPTED:
        return Colors.blue;
      case BookingStatus.IN_PROGRESS:
        return AppColors.primary;
      case BookingStatus.COMPLETED:
        return AppColors.success;
      case BookingStatus.CANCELLED:
        return Colors.red;
      case BookingStatus.DISPUTED:
        return Colors.redAccent;
    }
  }
}
