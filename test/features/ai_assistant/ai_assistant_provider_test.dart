import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/ai_assistant/presentation/providers/ai_assistant_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('AiAssistantNotifier Unit Tests', () {
    test('Initial state contains welcome message and quick replies', () {
      final state = container.read(aiAssistantProvider);
      expect(state.messages.length, equals(1));
      expect(state.messages.first.isUser, isFalse);
      expect(state.messages.first.quickReplies, isNotNull);
      expect(state.messages.first.quickReplies!.length, greaterThan(0));
      expect(state.isThinking, isFalse);
    });

    test('sendMessage adds user message and generates intent response for finding services', () async {
      final notifier = container.read(aiAssistantProvider.notifier);
      final future = notifier.sendMessage('Find plumber in Lusaka');
      
      final stateDuringThinking = container.read(aiAssistantProvider);
      expect(stateDuringThinking.messages.length, equals(2));
      expect(stateDuringThinking.messages.last.isUser, isTrue);
      expect(stateDuringThinking.isThinking, isTrue);

      await future;

      final finalState = container.read(aiAssistantProvider);
      expect(finalState.messages.length, equals(3));
      expect(finalState.messages.last.isUser, isFalse);
      expect(finalState.messages.last.text, contains('Verified Professionals'));
      expect(finalState.isThinking, isFalse);
    });

    test('sendMessage calculates escrow fee dynamically', () async {
      final notifier = container.read(aiAssistantProvider.notifier);
      await notifier.sendMessage('Calculate escrow fee for 1000 ZMW');

      final finalState = container.read(aiAssistantProvider);
      expect(finalState.messages.last.text, contains('Escrow Fee Breakdown'));
      expect(finalState.messages.last.text, contains('50.00'));
    });

    test('sendMessage returns inter-city bus schedule information', () async {
      final notifier = container.read(aiAssistantProvider.notifier);
      await notifier.sendMessage('What is the bus schedule to Ndola?');

      final finalState = container.read(aiAssistantProvider);
      expect(finalState.messages.last.text, contains('Inter-City Bus Schedules'));
      expect(finalState.messages.last.text, contains('Power Tools'));
    });

    test('clearChat resets conversation state', () async {
      final notifier = container.read(aiAssistantProvider.notifier);
      await notifier.sendMessage('Hello AI');
      notifier.clearChat();

      final state = container.read(aiAssistantProvider);
      expect(state.messages.length, equals(1));
      expect(state.messages.first.text, contains('Chat cleared!'));
    });
  });
}
