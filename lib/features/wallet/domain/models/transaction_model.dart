import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String txRef;
  final String type; // 'DEPOSIT' or 'WITHDRAWAL'
  final double amount;
  final String gateway;
  final String? network;
  final String status;
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.txRef,
    required this.type,
    required this.amount,
    required this.gateway,
    this.network,
    required this.status,
    required this.timestamp,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TransactionModel(
      id: documentId,
      txRef: data['txRef'] ?? '',
      type: data['type'] ?? 'DEPOSIT',
      amount: (data['amount'] ?? 0.0).toDouble(),
      gateway: data['gateway'] ?? '',
      network: data['network'],
      status: data['status'] ?? 'pending',
      timestamp: data['timestamp'] is Timestamp 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'txRef': txRef,
      'type': type,
      'amount': amount,
      'gateway': gateway,
      'network': network,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
