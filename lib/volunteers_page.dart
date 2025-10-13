import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteersPage extends StatefulWidget {
  const VolunteersPage({super.key});

  @override
  State<VolunteersPage> createState() => _VolunteersPageState();
}

class _VolunteersPageState extends State<VolunteersPage> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Volunteers"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by name or address",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          // 🔁 Firestore Stream — Works Offline with Cache
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('volunteers')
                  .orderBy('timestamp', descending: true)
                  .snapshots(includeMetadataChanges: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading volunteers."));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No volunteers found."));
                }

                final docs = snapshot.data!.docs;

                // 🔍 Filter by search text (name or address)
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['username']?.toLowerCase() ?? '';
                  final address = data['address']?.toLowerCase() ?? '';
                  return name.contains(searchText) || address.contains(searchText);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No matching volunteers found."));
                }

                // 📋 Display the volunteer list
                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 3,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(data['username'] ?? 'No Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📞 ${data['phone'] ?? 'N/A'}"),
                            Text("📍 ${data['address'] ?? 'Unknown'}"),
                            Text("🛠️ Skill: ${data['skill'] ?? 'Not specified'}"),
                            Text("🤝 Willing: ${data['willing'] == true ? 'Yes' : 'No'}"),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
