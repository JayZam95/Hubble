import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/presentation/widgets/hubble_image.dart';
import '../../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../../core/presentation/widgets/animated_empty_state.dart';
import '../../../domain/models/listing_model.dart';
import '../../providers/marketplace_provider.dart';
import '../listing_detail_screen.dart';

class TradespersonItem {
  final String id;
  final String name;
  final String avatarUrl;
  final String tradeTitle;
  final String discipline; // Plumbing, Electrical, Carpentry, HVAC, Painting, Roofing
  final double calloutFee;
  final double hourlyRate;
  final double rating;
  final int jobsCompleted;
  final bool isVerified;
  final bool isEmergency247;
  final String responseTime;
  final String location;
  final String specialties;

  const TradespersonItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.tradeTitle,
    required this.discipline,
    required this.calloutFee,
    required this.hourlyRate,
    required this.rating,
    required this.jobsCompleted,
    required this.isVerified,
    required this.isEmergency247,
    required this.responseTime,
    required this.location,
    required this.specialties,
  });
}

class HandymanCategoryScreen extends ConsumerStatefulWidget {
  const HandymanCategoryScreen({super.key});

  @override
  ConsumerState<HandymanCategoryScreen> createState() => _HandymanCategoryScreenState();
}

class _HandymanCategoryScreenState extends ConsumerState<HandymanCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedDiscipline = 'All Trades';
  bool _emergency247Only = false;
  bool _showCalculator = true;

  // Calculator State
  String _calcDiscipline = 'Plumbing';
  bool _calcIsEmergency = false;
  String _calcArea = 'Lusaka CBD / Rhodespark';
  double _calcEstimatedCallout = 150.0;
  double _calcMinLabor = 250.0;
  double _calcMaxLabor = 450.0;

  final List<String> _disciplines = [
    'All Trades',
    'Plumbing',
    'Electrical',
    'Carpentry',
    'HVAC & AC',
    'Painting',
    'Roofing',
    'Masonry',
  ];

  final List<String> _areas = [
    'Lusaka CBD / Rhodespark',
    'Woodlands / Kabulonga',
    'Roma / Foxdale',
    'Chelstone / Avondale',
    'Chilenje / Libala',
    'Kalingalinga / Mtendere',
    'Matero / Emmasdale',
  ];

  final List<TradespersonItem> _mockTradespeople = const [
    TradespersonItem(
      id: 'trade_1',
      name: 'Joe The Plumber',
      avatarUrl: 'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?auto=format&fit=crop&q=80',
      tradeTitle: 'Master Plumber & Borehole Specialist',
      discipline: 'Plumbing',
      calloutFee: 120.0,
      hourlyRate: 150.0,
      rating: 4.9,
      jobsCompleted: 154,
      isVerified: true,
      isEmergency247: true,
      responseTime: '⚡ 15-25 mins',
      location: 'Woodlands, Lusaka',
      specialties: 'Burst pipe repair, Geyser installation, Borehole pumps & Blocked drains',
    ),
    TradespersonItem(
      id: 'trade_2',
      name: 'Mabvuto Tembo',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=300&q=80',
      tradeTitle: 'Certified Industrial & Domestic Electrician',
      discipline: 'Electrical',
      calloutFee: 150.0,
      hourlyRate: 160.0,
      rating: 4.85,
      jobsCompleted: 98,
      isVerified: true,
      isEmergency247: true,
      responseTime: '⚡ 20 mins',
      location: 'Rhodespark, Lusaka',
      specialties: 'Short circuit triage, Inverter & Solar backup, DB board rewiring, Generator hookup',
    ),
    TradespersonItem(
      id: 'trade_3',
      name: 'Patrick Mwila',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?fit=crop&w=300&q=80',
      tradeTitle: 'Custom Furniture & Joinery Craftsman',
      discipline: 'Carpentry',
      calloutFee: 100.0,
      hourlyRate: 130.0,
      rating: 4.8,
      jobsCompleted: 76,
      isVerified: true,
      isEmergency247: false,
      responseTime: '45 mins',
      location: 'Roma, Lusaka',
      specialties: 'Kitchen cabinetry, Door & Lock fitting, Roof truss repair, Custom hardwood tables',
    ),
    TradespersonItem(
      id: 'trade_4',
      name: 'Kelvin Banda',
      avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?fit=crop&w=300&q=80',
      tradeTitle: 'HVAC, Refrigerator & Air Conditioning Tech',
      discipline: 'HVAC & AC',
      calloutFee: 140.0,
      hourlyRate: 175.0,
      rating: 4.95,
      jobsCompleted: 112,
      isVerified: true,
      isEmergency247: true,
      responseTime: '⚡ 30 mins',
      location: 'Kabulonga, Lusaka',
      specialties: 'AC gas refills, Cold room diagnostics, Compressor swaps, Home split unit servicing',
    ),
    TradespersonItem(
      id: 'trade_5',
      name: 'Brighton Chola',
      avatarUrl: 'https://images.unsplash.com/photo-1522529599102-193c0d76b5b6?fit=crop&w=300&q=80',
      tradeTitle: 'Interior / Exterior Painter & Waterproofing',
      discipline: 'Painting',
      calloutFee: 80.0,
      hourlyRate: 110.0,
      rating: 4.75,
      jobsCompleted: 64,
      isVerified: false,
      isEmergency247: false,
      responseTime: '1 hour',
      location: 'Avondale, Lusaka',
      specialties: 'Textured walls, Damp proofing, Epoxy floors, Commercial building recoats',
    ),
    TradespersonItem(
      id: 'trade_6',
      name: 'Isaac Lungu',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?fit=crop&w=300&q=80',
      tradeTitle: 'Roof Repair & Guttering Contractor',
      discipline: 'Roofing',
      calloutFee: 130.0,
      hourlyRate: 145.0,
      rating: 4.9,
      jobsCompleted: 88,
      isVerified: true,
      isEmergency247: true,
      responseTime: '⚡ 25 mins',
      location: 'Chelstone, Lusaka',
      specialties: 'Iron sheet leak patching, Gutter drainage, Ceiling board restorations',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _recalculateFee();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _recalculateFee() {
    double baseCallout = 100.0;
    double baseMin = 200.0;
    double baseMax = 400.0;

    switch (_calcDiscipline) {
      case 'Plumbing':
        baseCallout = 120.0;
        baseMin = 220.0;
        baseMax = 450.0;
        break;
      case 'Electrical':
        baseCallout = 140.0;
        baseMin = 250.0;
        baseMax = 500.0;
        break;
      case 'HVAC & AC':
        baseCallout = 150.0;
        baseMin = 300.0;
        baseMax = 650.0;
        break;
      case 'Roofing':
        baseCallout = 130.0;
        baseMin = 250.0;
        baseMax = 550.0;
        break;
      case 'Carpentry':
        baseCallout = 100.0;
        baseMin = 180.0;
        baseMax = 380.0;
        break;
      default:
        baseCallout = 90.0;
        baseMin = 150.0;
        baseMax = 350.0;
    }

    if (_calcIsEmergency) {
      baseCallout = baseCallout * 1.5;
      baseMin = baseMin * 1.3;
      baseMax = baseMax * 1.3;
    }

    setState(() {
      _calcEstimatedCallout = baseCallout;
      _calcMinLabor = baseMin;
      _calcMaxLabor = baseMax;
    });
  }

  void _openEmergencyQuoteModal(BuildContext context) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EmergencyQuoteSheet(
        discipline: _calcDiscipline,
        isEmergency: _calcIsEmergency || _emergency247Only,
        calloutEst: _calcEstimatedCallout,
        area: _calcArea,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    const orangeTheme = Color(0xFFEA580C); // Orange 600

    final allListingsAsync = ref.watch(allListingsProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Home Repairs & Trades',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Hero Banner with Emergency 24/7 Toggle ──────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFDC2626), Color(0xFFB45309)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.home_repair_service_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Certified Trades & Repairs',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Plumbers, Electricians, HVAC & Handymen',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Emergency 24/7 Switch Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _emergency247Only
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.emergency_rounded,
                                  color: _emergency247Only ? const Color(0xFFDC2626) : Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Emergency 24/7 Dispatch',
                                      style: TextStyle(
                                        color: _emergency247Only ? const Color(0xFFDC2626) : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Fast urgent response < 30 mins',
                                      style: TextStyle(
                                        color: _emergency247Only ? Colors.black87 : Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: _emergency247Only,
                              activeTrackColor: const Color(0xFFDC2626),
                              onChanged: (v) {
                                HapticFeedback.mediumImpact();
                                setState(() {
                                  _emergency247Only = v;
                                  _calcIsEmergency = v;
                                  _recalculateFee();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Instant Call-Out Fee Calculator Widget ──────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calculate_outlined, color: orangeTheme, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Instant Call-Out Fee Calculator',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showCalculator = !_showCalculator),
                            child: Icon(
                              _showCalculator ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      if (_showCalculator) ...[
                        const SizedBox(height: 14),
                        // Discipline Selector
                        const Text('Trade Discipline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['Plumbing', 'Electrical', 'HVAC & AC', 'Carpentry', 'Roofing', 'Painting'].map((d) {
                              final isSel = _calcDiscipline == d;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _calcDiscipline = d;
                                    _recalculateFee();
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSel ? orangeTheme : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    d,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                      color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Area Dropdown
                        const Text('Location Area (Lusaka)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _calcArea,
                              isExpanded: true,
                              dropdownColor: cardColor,
                              items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _calcArea = v);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Calculated Summary Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: orangeTheme.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: orangeTheme.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Estimated Call-Out Fee', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  Text(
                                    'K ${_calcEstimatedCallout.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Est. Labor Range', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  Text(
                                    'K ${_calcMinLabor.toStringAsFixed(0)} - ${_calcMaxLabor.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Request Emergency Quote CTA
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openEmergencyQuoteModal(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.flash_on_rounded, size: 18),
                            label: const Text('Request Emergency Quote & Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Search Field ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search plumbing, geyser, electrical, roofing...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: orangeTheme),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 4. Discipline Filter Chips ─────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _disciplines.map((d) {
                    final isSel = _selectedDiscipline == d;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDiscipline = d);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? orangeTheme : cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? orangeTheme : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // ── 5. Tradespeople / Listing Feed ─────────────────────────────
              allListingsAsync.when(
                data: (listings) {
                  // Filter live marketplace listings
                  final repairListings = listings.where((l) {
                    final cat = l.category.toLowerCase();
                    return cat.contains('plumb') || cat.contains('repair') || cat.contains('trade') || cat.contains('electric') || cat.contains('home');
                  }).toList();

                  // Filter mock tradespeople
                  final filteredTrades = _mockTradespeople.where((t) {
                    if (_selectedDiscipline != 'All Trades' && !t.discipline.toLowerCase().contains(_selectedDiscipline.toLowerCase())) {
                      return false;
                    }
                    if (_emergency247Only && !t.isEmergency247) return false;
                    if (_searchQuery.isNotEmpty) {
                      final matchName = t.name.toLowerCase().contains(_searchQuery);
                      final matchTitle = t.tradeTitle.toLowerCase().contains(_searchQuery);
                      final matchSpec = t.specialties.toLowerCase().contains(_searchQuery);
                      if (!matchName && !matchTitle && !matchSpec) return false;
                    }
                    return true;
                  }).toList();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Tradespeople (${filteredTrades.length + repairListings.length})',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (_emergency247Only)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '🚨 24/7 On-Call',
                                  style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Live marketplace listings
                        if (repairListings.isNotEmpty) ...[
                          ...repairListings.map((l) => _buildLiveListingCard(context, l, isDark, cardColor, orangeTheme)),
                          const SizedBox(height: 8),
                        ],

                        if (filteredTrades.isEmpty && repairListings.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: AnimatedEmptyState(
                              icon: Icons.handyman_outlined,
                              title: 'No Tradespeople Found',
                              subtitle: 'Try changing your trade discipline or toggling off emergency filter.',
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredTrades.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final trade = filteredTrades[index];
                              return _buildTradeCard(context, trade, isDark, cardColor, orangeTheme);
                            },
                          ),
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: ShimmerListTile(),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error loading trades: $e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTradeCard(
    BuildContext context,
    TradespersonItem trade,
    bool isDark,
    Color cardColor,
    Color orangeTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: trade.isEmergency247 ? const Color(0xFFDC2626).withValues(alpha: 0.3) : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          width: trade.isEmergency247 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: orangeTheme.withValues(alpha: 0.1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: HubbleImage(
                        imagePath: trade.avatarUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (trade.isVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            trade.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: orangeTheme.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            trade.discipline,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: orangeTheme),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trade.tradeTitle,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${trade.rating} (${trade.jobsCompleted} jobs)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trade.responseTime,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Specialties Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.build_circle_outlined, size: 14, color: Color(0xFFEA580C)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trade.specialties,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Pricing Row: Callout & Hourly
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Call-out: K ${trade.calloutFee.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rate: K ${trade.hourlyRate.toStringAsFixed(0)}/hr',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
              if (trade.isEmergency247)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '24/7 DISPATCH',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _openEmergencyQuoteModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: trade.isEmergency247 ? const Color(0xFFDC2626) : orangeTheme,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(trade.isEmergency247 ? Icons.flash_on_rounded : Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    trade.isEmergency247 ? 'Dispatch / Request' : 'Book Repair',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showTradeDetailsSheet(context, trade);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: orangeTheme,
                    side: BorderSide(color: orangeTheme.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveListingCard(
    BuildContext context,
    ListingModel listing,
    bool isDark,
    Color cardColor,
    Color orangeTheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: orangeTheme.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 65,
                  height: 65,
                  child: listing.images.isNotEmpty && listing.images.first.isNotEmpty
                      ? HubbleImage(imagePath: listing.images.first, fit: BoxFit.cover)
                      : Container(
                          color: orangeTheme.withValues(alpha: 0.15),
                          child: Icon(Icons.home_repair_service_rounded, color: orangeTheme, size: 30),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('by ${listing.providerName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      'K ${listing.price.toStringAsFixed(0)} / ${listing.billingType.name}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openEmergencyQuoteModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeTheme,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: const Text('Request Quote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)));
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
                child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTradeDetailsSheet(BuildContext context, TradespersonItem trade) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: HubbleImage(imagePath: trade.avatarUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trade.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(trade.tradeTitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        Text('Callout K ${trade.calloutFee.toStringAsFixed(0)} • Rate K ${trade.hourlyRate.toStringAsFixed(0)}/hr',
                            style: const TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Specialties & Scope of Work', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Text(trade.specialties, style: const TextStyle(fontSize: 13, height: 1.4)),
              const SizedBox(height: 14),
              const Text('Service Area & Response Window', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text('${trade.location} (Average response: ${trade.responseTime})', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openEmergencyQuoteModal(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.flash_on_rounded),
                  label: const Text('Request Dispatch & Emergency Quote', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmergencyQuoteSheet extends StatefulWidget {
  final String discipline;
  final bool isEmergency;
  final double calloutEst;
  final String area;

  const _EmergencyQuoteSheet({
    required this.discipline,
    required this.isEmergency,
    required this.calloutEst,
    required this.area,
  });

  @override
  State<_EmergencyQuoteSheet> createState() => _EmergencyQuoteSheetState();
}

class _EmergencyQuoteSheetState extends State<_EmergencyQuoteSheet> {
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSubmitting = false;
  String _urgencyTier = 'Immediate (< 30 mins)';

  @override
  void dispose() {
    _issueController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Color(0xFFDC2626), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.discipline} Emergency Dispatch',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      Text(
                        'Location: ${widget.area}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Callout summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Standard Dispatch Callout:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    'K ${widget.calloutEst.toStringAsFixed(0)}',
                    style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text('Urgency Tier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: ['Immediate (< 30 mins)', 'Today within 2 hrs', 'Scheduled Tomorrow'].map((tier) {
                final isSel = _urgencyTier == tier;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _urgencyTier = tier),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFDC2626) : (isDark ? Colors.white10 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          tier,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            const Text('Describe Problem / Leak / Outage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _issueController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Main water pipe burst behind bathroom wall, or tripping breaker board...',
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 14),
            const Text('Contact Phone Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+260 97X XXX XXX',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isSubmitting = true);
                        await Future.delayed(const Duration(milliseconds: 700));
                        if (!mounted) return;
                        setState(() => _isSubmitting = false);
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFFDC2626),
                            content: Text('Emergency quote & dispatch sent to nearest ${widget.discipline} providers!'),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Dispatch Certified Tradesperson',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
