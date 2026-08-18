import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? quickReplies;
  final Map<String, dynamic>? intentData;

  AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickReplies,
    this.intentData,
  });
}

class AiAssistantState {
  final List<AiChatMessage> messages;
  final bool isThinking;

  AiAssistantState({
    required this.messages,
    this.isThinking = false,
  });

  AiAssistantState copyWith({
    List<AiChatMessage>? messages,
    bool? isThinking,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
    );
  }
}

class AiAssistantNotifier extends Notifier<AiAssistantState> {
  @override
  AiAssistantState build() {
    return AiAssistantState(
      messages: [
        AiChatMessage(
          id: 'welcome_msg',
          text:
              '👋 Hello! I am Hubble AI, your intelligent platform assistant.\n\nI can assist you with finding verified service providers in Zambia, calculating escrow fees, checking bus schedules, and explaining buyer protection.',
          isUser: false,
          timestamp: DateTime.now(),
          quickReplies: [
            '🔍 Find Plumber in Lusaka',
            '🧮 Calculate Escrow Fee',
            '🚌 Lusaka to Ndola Bus Schedule',
            '🛡️ How does Escrow work?',
          ],
        ),
      ],
    );
  }

  Future<void> sendMessage(String userQuery) async {
    final trimmed = userQuery.trim();
    if (trimmed.isEmpty) return;

    final userMsg = AiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isThinking: true,
    );

    // Simulate smart AI response thinking delay
    await Future.delayed(const Duration(milliseconds: 900));

    final aiResponse = _generateIntentResponse(trimmed);

    state = state.copyWith(
      messages: [...state.messages, aiResponse],
      isThinking: false,
    );
  }

  void clearChat() {
    state = AiAssistantState(
      messages: [
        AiChatMessage(
          id: 'welcome_msg_${DateTime.now().millisecondsSinceEpoch}',
          text:
              'Chat cleared! How else can I assist you with Hubble services today?',
          isUser: false,
          timestamp: DateTime.now(),
          quickReplies: [
            '🔍 Find Plumber in Lusaka',
            '🧮 Calculate Escrow Fee',
            '🚌 Lusaka to Ndola Bus Schedule',
            '🛡️ How does Escrow work?',
          ],
        ),
      ],
    );
  }

  AiChatMessage _generateIntentResponse(String query) {
    final lower = query.toLowerCase();
    final id = 'ai_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Service Finding Intent
    if (lower.contains('find') ||
        lower.contains('search') ||
        lower.contains('plumber') ||
        lower.contains('electrician') ||
        lower.contains('cleaner') ||
        lower.contains('tutor') ||
        lower.contains('mechanic') ||
        lower.contains('service') ||
        lower.contains('hire')) {
      return AiChatMessage(
        id: id,
        text: '🔎 **Found Verified Professionals in Zambia**\n\n'
            'Here are top-rated service providers matching your request:\n\n'
            '• **Kabwe Plumbing & Drain Pros** - 4.9 ★ (Lusaka)\n'
            '  *Rate:* K150 / hr • Escrow Protected\n\n'
            '• **Chisa Electrical Solutions** - 4.8 ★ (Kitwe)\n'
            '  *Rate:* K200 / hr • Gov Verified\n\n'
            '• **CleanSpark Commercial Services** - 5.0 ★ (Ndola)\n'
            '  *Rate:* K180 / hr • Instant Booking\n\n'
            '💡 *Tip: Tap on any listing in the Explore tab to chat directly or book instantly!*',
        isUser: false,
        timestamp: DateTime.now(),
        quickReplies: [
          '🧮 Calculate Escrow Fee',
          '🛡️ How to Book',
        ],
        intentData: {'type': 'services_found', 'count': 3},
      );
    }

    // 2. Escrow Fee Calculation Intent
    if (lower.contains('escrow') ||
        lower.contains('fee') ||
        lower.contains('calculate') ||
        lower.contains('cost') ||
        lower.contains('commission') ||
        lower.contains('charge')) {
      final double? parsedAmount = _extractAmount(lower);

      if (parsedAmount != null && parsedAmount > 0) {
        final platformFee = parsedAmount * 0.05;
        final providerPayout = parsedAmount - platformFee;
        return AiChatMessage(
          id: id,
          text: '🧮 **Escrow Fee Breakdown (ZMW ${parsedAmount.toStringAsFixed(2)})**\n\n'
              '• **Job Price:** ZMW ${parsedAmount.toStringAsFixed(2)}\n'
              '• **Hubble Buyer Protection Fee (5%):** ZMW ${platformFee.toStringAsFixed(2)}\n'
              '• **Net Provider Payout:** ZMW ${providerPayout.toStringAsFixed(2)}\n\n'
              '🔒 Funds are safely held in escrow until the job is completed and confirmed by the client!',
          isUser: false,
          timestamp: DateTime.now(),
          quickReplies: [
            '🛡️ What if there is a dispute?',
            '💳 Payment Methods Supported',
          ],
        );
      }

      return AiChatMessage(
        id: id,
        text: '🧮 **Hubble Escrow Fee Calculator**\n\n'
            'Hubble charges a flat **5% Platform Protection Fee** on service bookings to guarantee 100% money-back escrow security.\n\n'
            '*Sample Calculation:* For a **ZMW 1,000** job:\n'
            '• Escrow Fee (5%): ZMW 50.00\n'
            '• Provider Payout: ZMW 950.00\n\n'
            '💬 Type *"Calculate escrow fee for 2500 ZMW"* to get an instant breakdown for any amount!',
        isUser: false,
        timestamp: DateTime.now(),
        quickReplies: [
          'Calculate escrow fee for 500 ZMW',
          'Calculate escrow fee for 2000 ZMW',
        ],
      );
    }

    // 3. Bus Schedule Intent
    if (lower.contains('bus') ||
        lower.contains('schedule') ||
        lower.contains('ticket') ||
        lower.contains('travel') ||
        lower.contains('ndola') ||
        lower.contains('livingstone') ||
        lower.contains('chipata') ||
        lower.contains('solwezi')) {
      return AiChatMessage(
        id: id,
        text: '🚌 **Inter-City Bus Schedules in Zambia**\n\n'
            '**Route: Lusaka ↔ Ndola / Kitwe**\n'
            '• **Power Tools Luxury Coach**\n'
            '  *Departures:* 06:00, 09:30, 14:00 | ZMW 220 (VIP)\n\n'
            '• **Mazhandu Family Bus**\n'
            '  *Departures:* 07:15, 11:00, 16:30 | ZMW 190 (Standard)\n\n'
            '**Route: Lusaka ↔ Livingstone**\n'
            '• **Shalom Express**\n'
            '  *Departures:* 06:30, 13:00 | ZMW 280 (VIP)\n\n'
            '🎟️ *You can book bus tickets directly and download digital PDF receipts on Hubble!*',
        isUser: false,
        timestamp: DateTime.now(),
        quickReplies: [
          '🎟️ Book Bus Ticket',
          '📄 Download PDF Receipt',
        ],
      );
    }

    // 4. Platform FAQ / Buyer Protection Intent
    if (lower.contains('faq') ||
        lower.contains('how') ||
        lower.contains('work') ||
        lower.contains('safe') ||
        lower.contains('protection') ||
        lower.contains('dispute') ||
        lower.contains('refund') ||
        lower.contains('payment') ||
        lower.contains('mobile money')) {
      return AiChatMessage(
        id: id,
        text: '🛡️ **Hubble Platform Guarantees & FAQ**\n\n'
            '1. **100% Escrow Protection:** Payouts are locked until you verify work completion.\n'
            '2. **Government ID Verified Providers:** Look for the blue checkmark badge on provider profiles.\n'
            '3. **Mobile Money Payouts:** MTN, Airtel, and Zamtel integrated for instant withdrawals.\n'
            '4. **Dispute Resolution:** Built-in resolution center for client & provider arbitration.\n'
            '5. **PDF Invoicing:** Download official digital tax receipts for all transactions.',
        isUser: false,
        timestamp: DateTime.now(),
        quickReplies: [
          '🏆 Rewards Program',
          '❤️ Saved Favorites',
        ],
      );
    }

    // 5. Default Fallback
    return AiChatMessage(
      id: id,
      text: '🤖 I am here to help! I can assist you with:\n'
          '• Finding local service providers & prices\n'
          '• Dynamic escrow fee calculations\n'
          '• Checking inter-city bus routes and schedules\n'
          '• Platform guarantees, digital PDF receipts, and rewards.\n\n'
          'Try asking one of the quick suggestions below!',
      isUser: false,
      timestamp: DateTime.now(),
      quickReplies: [
        '🔍 Find Electrician in Lusaka',
        '🧮 Calculate Escrow Fee for 1500 ZMW',
        '🚌 Lusaka to Ndola Bus Schedule',
        '🛡️ How does Escrow work?',
      ],
    );
  }

  double? _extractAmount(String input) {
    final RegExp regExp = RegExp(r'\b\d+(?:\.\d+)?\b');
    final match = regExp.firstMatch(input);
    if (match != null) {
      return double.tryParse(match.group(0)!);
    }
    return null;
  }
}

final aiAssistantProvider =
    NotifierProvider<AiAssistantNotifier, AiAssistantState>(AiAssistantNotifier.new);
