import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class OfflineAlertPage extends StatefulWidget {
  const OfflineAlertPage({super.key});

  @override
  State<OfflineAlertPage> createState() => _OfflineAlertPageState();
}

class _OfflineAlertPageState extends State<OfflineAlertPage> {
  final TextEditingController _messageController = TextEditingController();
  List<String> phoneNumbers = [];
  bool isLoading = true;
  bool isSending = false;

  // Load phone numbers from Firestore
  Future<void> _loadPhoneNumbers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final seen = <String>{};

      final fetchedNumbers = snapshot.docs
          .map((doc) => doc.data()['phone']?.toString().trim())
          .where((phone) => phone != null && phone.isNotEmpty && seen.add(phone!))
          .toList();

      setState(() {
        phoneNumbers = fetchedNumbers.cast<String>();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error loading phone numbers: $e")),
      );
    }
  }

  // Send SMS using Firebase Cloud Function (Twilio)
  Future<void> _sendSMS(String message, List<String> recipients) async {
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Message cannot be empty")),
      );
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      final functions = FirebaseFunctions.instance;

      for (String phone in recipients) {
        final result = await functions.httpsCallable('sendSMS').call({
          'to': phone,         // recipient number including country code, e.g., '+919876543210'
          'message': message,  // message text
        });

        print(result.data['result']); // logs SMS status
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ SMS Alert sent to all recipients"), backgroundColor: Colors.green),
      );

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to send SMS: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPhoneNumbers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offline Alert (SMS)"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Alert Message",
                      border: OutlineInputBorder(),
                      hintText: "Type the disaster alert here...",
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: (phoneNumbers.isNotEmpty && !isSending)
                        ? () => _sendSMS(_messageController.text.trim(), phoneNumbers)
                        : null,
                    icon: const Icon(Icons.sms),
                    label: isSending
                        ? const Text("Sending...")
                        : const Text("Send SMS to All"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                  const SizedBox(height: 20),
                  Text("📋 Total Recipients: ${phoneNumbers.length}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.builder(
                      itemCount: phoneNumbers.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.phone),
                          title: Text(phoneNumbers[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
