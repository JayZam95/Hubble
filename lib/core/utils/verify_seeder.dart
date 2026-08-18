import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hubble/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VerifyApp());
}

class VerifyApp extends StatelessWidget {
  const VerifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VerifyWidget(),
    );
  }
}

class VerifyWidget extends StatefulWidget {
  const VerifyWidget({super.key});

  @override
  State<VerifyWidget> createState() => _VerifyWidgetState();
}

class _VerifyWidgetState extends State<VerifyWidget> {
  String _status = 'Checking Firebase...';

  @override
  void initState() {
    super.initState();
    _checkDatabase();
  }

  Future<void> _checkDatabase() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final query = await firestore.collection('users').get(const GetOptions(source: Source.server));
      
      setState(() {
        _status = 'Found ${query.docs.length} documents in the "users" collection on the SERVER.';
      });
      debugPrint('=== SERVER CHECK: Found ${query.docs.length} users. ===');
      for (var doc in query.docs) {
         debugPrint('User: ${doc.id}');
      }
    } catch (e) {
      setState(() {
        _status = 'Error checking: $e';
      });
      debugPrint('=== SERVER CHECK ERROR: $e ===');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Firebase')),
      body: Center(child: Text(_status, textAlign: TextAlign.center)),
    );
  }
}
