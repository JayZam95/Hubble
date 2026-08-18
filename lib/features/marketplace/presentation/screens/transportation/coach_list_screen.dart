import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../domain/models/bus_trip_model.dart';
import '../../providers/transportation_provider.dart';
import 'bus_seat_plan_screen.dart';

enum TimeFilterSlot { all, morning, afternoon, evening }

class CoachListScreen extends ConsumerStatefulWidget {
  const CoachListScreen({super.key});

  @override
  ConsumerState<CoachListScreen> createState() => _CoachListScreenState();
}

class _CoachListScreenState extends ConsumerState<CoachListScreen> {
  DateTime _selectedDate = DateTime.now();

  // Filters
  String _selectedOrigin = 'Lusaka';
  String _selectedDestination = 'All Destinations';
  TimeFilterSlot _selectedTimeSlot = TimeFilterSlot.all;
  String _selectedClass = 'All Classes';
  String _selectedCompany = 'All Companies';

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _swapOriginDestination() {
    setState(() {
      final oldOrigin = _selectedOrigin;
      final oldDest = _selectedDestination;

      if (oldDest == 'All Destinations') {
        _selectedOrigin = 'Livingstone';
        _selectedDestination = oldOrigin == 'All Origins' ? 'Lusaka' : oldOrigin;
      } else if (oldOrigin == 'All Origins') {
        _selectedOrigin = oldDest;
        _selectedDestination = 'Lusaka';
      } else {
        _selectedOrigin = oldDest;
        _selectedDestination = oldOrigin;
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedOrigin = 'Lusaka';
      _selectedDestination = 'All Destinations';
      _selectedTimeSlot = TimeFilterSlot.all;
      _selectedClass = 'All Classes';
      _selectedCompany = 'All Companies';
    });
  }

  List<BusTripModel> _applyFilters(List<BusTripModel> trips) {
    return trips.where((trip) {
      // 1. Origin Filter
      if (_selectedOrigin != 'All Origins' &&
          trip.origin.toLowerCase() != _selectedOrigin.toLowerCase()) {
        return false;
      }

      // 2. Destination Filter
      if (_selectedDestination != 'All Destinations' &&
          trip.destination.toLowerCase() != _selectedDestination.toLowerCase()) {
        return false;
      }

      // 3. Time Filter
      final hour = trip.departureTime.hour;
      if (_selectedTimeSlot == TimeFilterSlot.morning) {
        if (hour < 5 || hour >= 12) return false;
      } else if (_selectedTimeSlot == TimeFilterSlot.afternoon) {
        if (hour < 12 || hour >= 17) return false;
      } else if (_selectedTimeSlot == TimeFilterSlot.evening) {
        if (hour >= 5 && hour < 17) return false;
      }

      // 4. Bus Class Filter
      if (_selectedClass != 'All Classes' &&
          trip.busClass.toLowerCase() != _selectedClass.toLowerCase()) {
        return false;
      }

      // 5. Company Filter
      if (_selectedCompany != 'All Companies' &&
          trip.companyName.toLowerCase() != _selectedCompany.toLowerCase()) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showCityPicker({
    required BuildContext context,
    required String title,
    required String currentValue,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h2.copyWith(fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final item = options[index];
                      final isSelected = item == currentValue;
                      return ListTile(
                        title: Text(
                          item,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                            : null,
                        onTap: () {
                          onSelected(item);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(busTripsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary =
        isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary =
        isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    final dateLabel = DateFormat('EEE, d MMM yyyy').format(_selectedDate);

    final hasActiveFilters = _selectedOrigin != 'Lusaka' ||
        _selectedDestination != 'All Destinations' ||
        _selectedTimeSlot != TimeFilterSlot.all ||
        _selectedClass != 'All Classes' ||
        _selectedCompany != 'All Companies';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Intercity Coaches',
          style: AppTextStyles.h2,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: [
          if (hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: 'Reset Filters',
              onPressed: _resetFilters,
            ),
        ],
      ),
      body: tripsAsync.when(
        data: (allTrips) {
          // Dynamic lists of available origins and destinations
          final availableOrigins = [
            'All Origins',
            ...allTrips.map((t) => t.origin).toSet().toList()..sort()
          ];
          final availableDestinations = [
            'All Destinations',
            ...allTrips.map((t) => t.destination).toSet().toList()..sort()
          ];
          final availableCompanies = [
            'All Companies',
            ...allTrips.map((t) => t.companyName).toSet().toList()..sort()
          ];
          final availableClasses = [
            'All Classes',
            ...allTrips.map((t) => t.busClass).toSet().toList()..sort()
          ];

          final filteredTrips = _applyFilters(allTrips);

          return Column(
            children: [
              // ── Travel Header Card (Date + Interchangeable Route) ──────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Date Selector Row
                      GestureDetector(
                        onTap: () => _pickDate(context),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              dateLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Change Date',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1),
                      ),

                      // Interchangeable Route Selector Row
                      Row(
                        children: [
                          // Origin Picker
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _showCityPicker(
                                  context: context,
                                  title: 'Select Departure City',
                                  currentValue: _selectedOrigin,
                                  options: availableOrigins,
                                  onSelected: (val) =>
                                      setState(() => _selectedOrigin = val),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : AppColors.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'FROM',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: textSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.trip_origin_rounded,
                                            size: 14, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _selectedOrigin,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Swap Button (⇄)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Material(
                              color: AppColors.primary,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _swapOriginDestination,
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.swap_horiz_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Destination Picker
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _showCityPicker(
                                  context: context,
                                  title: 'Select Destination City',
                                  currentValue: _selectedDestination,
                                  options: availableDestinations,
                                  onSelected: (val) =>
                                      setState(() => _selectedDestination = val),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : AppColors.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: textSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.place_rounded,
                                            size: 14, color: AppColors.accent),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _selectedDestination,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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

              const SizedBox(height: 8),

              // ── Filter Bar (Time, Class, Company) ──────────────────────────────
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Time Slot Chips
                    _buildTimeFilterChip(
                      slot: TimeFilterSlot.all,
                      label: 'All Times',
                      icon: Icons.access_time_filled_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildTimeFilterChip(
                      slot: TimeFilterSlot.morning,
                      label: 'Morning (05-12)',
                      icon: Icons.wb_sunny_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildTimeFilterChip(
                      slot: TimeFilterSlot.afternoon,
                      label: 'Afternoon (12-17)',
                      icon: Icons.wb_twilight_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildTimeFilterChip(
                      slot: TimeFilterSlot.evening,
                      label: 'Evening/Night (17-05)',
                      icon: Icons.nights_stay_rounded,
                    ),
                    const SizedBox(width: 12),

                    // Vertical Divider
                    Container(width: 1, height: 20, color: Colors.grey.withValues(alpha: 0.3)),
                    const SizedBox(width: 12),

                    // Class Dropdown Chip
                    _buildDropdownFilterChip(
                      label: _selectedClass,
                      icon: Icons.airline_seat_recline_extra_rounded,
                      options: availableClasses,
                      onSelected: (val) => setState(() => _selectedClass = val),
                    ),
                    const SizedBox(width: 8),

                    // Company Dropdown Chip
                    _buildDropdownFilterChip(
                      label: _selectedCompany,
                      icon: Icons.directions_bus_rounded,
                      options: availableCompanies,
                      onSelected: (val) => setState(() => _selectedCompany = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Results Summary Bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '${filteredTrips.length} bus${filteredTrips.length == 1 ? '' : 'es'} available',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (hasActiveFilters)
                      GestureDetector(
                        onTap: _resetFilters,
                        child: Text(
                          'Clear Filters',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // ── Bus List / Empty View ────────────────────────────────────────
              Expanded(
                child: filteredTrips.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_bus_filled_outlined,
                              size: 54,
                              color: textSecondary.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No buses match your filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try swapping origins or clearing filters.',
                              style: TextStyle(fontSize: 13, color: textSecondary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _resetFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Reset All Filters'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredTrips.length,
                        itemBuilder: (context, index) {
                          final trip = filteredTrips[index];
                          return _BusTripCard(
                            trip: trip,
                            isDark: isDark,
                            cardColor: cardColor,
                            selectedDate: _selectedDate,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error loading trips: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilterChip({
    required TimeFilterSlot slot,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTimeSlot == slot;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected
            ? Colors.white
            : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      onSelected: (_) {
        setState(() => _selectedTimeSlot = slot);
      },
    );
  }

  Widget _buildDropdownFilterChip({
    required String label,
    required IconData icon,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    final isSelected = !label.startsWith('All');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _showCityPicker(
          context: context,
          title: 'Filter by ${icon == Icons.directions_bus_rounded ? "Company" : "Bus Class"}',
          currentValue: label,
          options: options,
          onSelected: onSelected,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: isSelected ? AppColors.primary : (isDark ? Colors.white54 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual bus card
// ---------------------------------------------------------------------------
class _BusTripCard extends StatelessWidget {
  final BusTripModel trip;
  final bool isDark;
  final Color cardColor;
  final DateTime selectedDate;

  const _BusTripCard({
    required this.trip,
    required this.isDark,
    required this.cardColor,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary =
        isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    final available = trip.availableCount;
    final isFilling = available < 10;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusSeatPlanScreen(
              trip: trip,
              travelDate: selectedDate,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(trip.companyColorValue),
                          Color(trip.companyColorValue).withValues(alpha: 0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.directions_bus_filled_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bus name + class badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                trip.companyName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            _ClassBadge(busClass: trip.busClass),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Route: Origin → Destination
                        Row(
                          children: [
                            const Icon(Icons.circle,
                                size: 8, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              trip.origin,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: textSecondary),
                            ),
                            Text(
                              trip.destination,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Times
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 13, color: textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('HH:mm').format(trip.departureTime)}  →  ${DateFormat('HH:mm').format(trip.arrivalTime)}',
                              style: TextStyle(
                                  fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom bar ─────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Seat count
                  Icon(
                    Icons.event_seat_rounded,
                    size: 14,
                    color: isFilling ? AppColors.warning : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$available seats left',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isFilling ? AppColors.warning : AppColors.primary,
                    ),
                  ),
                  const Spacer(),

                  // Price + CTA
                  Text(
                    'K ${trip.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/seat',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Select Seat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassBadge extends StatelessWidget {
  final String busClass;
  const _ClassBadge({required this.busClass});

  @override
  Widget build(BuildContext context) {
    final isExpress = busClass == 'Express';
    final isSleeper = busClass == 'Sleeper';
    final isLuxury = busClass == 'Luxury';

    final color = isSleeper
        ? Colors.purple
        : isLuxury
            ? Colors.amber.shade800
            : isExpress
                ? AppColors.accent
                : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        busClass.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

