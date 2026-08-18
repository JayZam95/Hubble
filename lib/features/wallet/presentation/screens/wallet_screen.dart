import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/payment_provider.dart';

import 'package:intl/intl.dart';


class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wallet')),
        body: const Center(child: Text('Please log in to view your wallet.')),
      );
    }

    final ledger = user.financialLedger;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Wallet & Earnings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Available Balance Card
            _buildBalanceCard(
              context: context,
              title: 'Available Balance',
              amount: ledger.availableBalance,
              currency: ledger.currency,
              isDark: isDark,
              gradient: AppColors.primaryGradient,
              icon: Icons.account_balance_wallet,
            ),
            const SizedBox(height: 16),
            // Vault/Escrow Balance Card
            _buildBalanceCard(
              context: context,
              title: 'Vault (Escrow) Balance',
              amount: ledger.vaultSettings.vaultBalance,
              currency: ledger.currency,
              isDark: isDark,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.shield,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Wallet Actions', isDark),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleDeposit(context, ref, user.uid),
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    label: const Text('Top Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleWithdraw(context, ref, user.uid, ledger.availableBalance),
                    icon: const Icon(Icons.arrow_circle_up),
                    label: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Recent Transactions', isDark),
            _buildTransactionList(ref, user.uid, isDark, ledger.currency),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeposit(BuildContext context, WidgetRef ref, String userId) async {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedNetwork = 'MTN';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Top Up via Mobile Money'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: 'K ', hintText: '0.00', labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'e.g. 0961234567', labelText: 'Phone Number'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedNetwork,
                  items: ['MTN', 'AIRTEL', 'ZAMTEL'].map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                  onChanged: (val) => setState(() => selectedNetwork = val!),
                  decoration: const InputDecoration(labelText: 'Network'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(amountController.text);
                  if (val == null || val <= 0 || phoneController.text.isEmpty) return;
                  Navigator.pop(context, {'amount': val, 'phone': phoneController.text, 'network': selectedNetwork});
                },
                child: const Text('Continue'),
              ),
            ],
          );
        }
      ),
    );

    if (result == null) return;
    
    if (context.mounted) {
      try {
        await ref.read(paymentControllerProvider.notifier).topUpWallet(result['amount'], result['phone'], result['network']);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please check your phone for the PIN prompt. Your balance will update shortly.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Top up failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleWithdraw(BuildContext context, WidgetRef ref, String userId, double availableBalance) async {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedNetwork = 'MTN';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Withdraw Funds'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available: K ${availableBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: 'K ', hintText: '0.00', labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'e.g. 0961234567', labelText: 'Mobile Money Number'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedNetwork,
                  items: ['MTN', 'AIRTEL', 'ZAMTEL'].map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                  onChanged: (val) => setState(() => selectedNetwork = val!),
                  decoration: const InputDecoration(labelText: 'Network'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(amountController.text);
                  if (val == null || val <= 0 || val > availableBalance || phoneController.text.isEmpty) {
                    return; // Basic validation
                  }
                  Navigator.pop(context, {'amount': val, 'phone': phoneController.text, 'network': selectedNetwork});
                },
                child: const Text('Withdraw'),
              ),
            ],
          );
        }
      ),
    );

    if (result == null) return;
    
    if (context.mounted) {
      try {
        await ref.read(paymentControllerProvider.notifier).requestWithdrawal(result['amount'], result['phone'], result['network']);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Withdrawal requested! Funds will reflect in your mobile money account shortly.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Withdrawal failed: $e')),
          );
        }
      }
    }
  }

  Widget _buildBalanceCard({
    required BuildContext context,
    required String title,
    required double amount,
    required String currency,
    required bool isDark,
    required Gradient gradient,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.first).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildPremiumCard({required bool isDark, required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(20)}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }

  Widget _buildTransactionList(WidgetRef ref, String userId, bool isDark, String currency) {
    final historyAsync = ref.watch(transactionHistoryProvider(userId));

    return _buildPremiumCard(
      isDark: isDark,
      padding: EdgeInsets.zero,
      child: historyAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No recent transactions.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isDeposit = tx.type.toUpperCase() == 'DEPOSIT';
              final color = isDeposit ? Colors.green : (isDark ? Colors.redAccent : Colors.red);
              final icon = isDeposit ? Icons.arrow_downward : Icons.arrow_upward;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                title: Text(
                  tx.type.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(tx.timestamp),
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isDeposit ? '+' : '-'} $currency ${tx.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: tx.status == 'success' 
                            ? Colors.green 
                            : (tx.status == 'pending' ? Colors.orange : Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'Failed to load transactions',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ),
      ),
    );
  }
}
