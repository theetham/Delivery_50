import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/pages/login.dart';
import 'package:delivery_app/pages/rider/ProductDetailPage.dart';
import 'package:flutter/material.dart';

class HomepageRider extends StatefulWidget {
  final String phone;
  final String role;
  final String userId;

  const HomepageRider({
    super.key,
    required this.phone,
    required this.role,
    required this.userId,
  });

  @override
  State<HomepageRider> createState() => _HomepageRiderState();
}

class _HomepageRiderState extends State<HomepageRider> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> acceptJob(String productId) async {
    try {
      await db.collection("Products").doc(productId).update({
        "riderId": widget.userId,
        "riderPhone": widget.phone,
        "status": "ไรเดอร์รับงานแล้ว (กำลังเดินทางมารับสินค้า)",
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("รับงานเรียบร้อย ✅")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }

  Future<Map<String, String>> getSenderInfo(String senderId) async {
    try {
      if (senderId.isEmpty) return {'name': '-', 'phone': '-'};
      final doc = await db.collection('Users').doc(senderId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'name': data['fullname'] ?? '-',
          'phone': data['phone'] ?? '-',
        };
      }
    } catch (e) {}
    return {'name': '-', 'phone': '-'};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA64C),
        automaticallyImplyLeading: false,
        title: const Text(
          'งานของฉัน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("ออกจากระบบสำเร็จ ✅")));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text('ออกจากระบบ')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection("Products").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text("ยังไม่มีสินค้าจากลูกค้า 📦"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              final productId = products[index].id;
              final hasRider = data.containsKey('riderId');

              return FutureBuilder<Map<String, String>>(
                future: getSenderInfo(data['senderId'] ?? ''),
                builder: (context, senderSnapshot) {
                  final senderName = senderSnapshot.data?['name'] ?? '-';
                  final senderPhone = senderSnapshot.data?['phone'] ?? '-';

                  return GestureDetector(
                    onTap: () {
                      // กดไปหน้า detail
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(
                            productData: data,
                            senderName: senderName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE1C0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: data['productImage'] != null &&
                                    data['productImage'].toString().isNotEmpty
                                ? Image.memory(
                                    base64Decode(data['productImage']),
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'assets/no_image.png',
                                    width: 90,
                                    height: 90,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['productName'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text("ผู้ส่ง: $senderName",
                                    style: const TextStyle(fontSize: 14)),
                                Text("เบอร์ผู้ส่ง: $senderPhone",
                                    style: const TextStyle(fontSize: 14)),
                                Text(
                                    "ผู้รับ: ${data['receiverName'] ?? '-'}",
                                    style: const TextStyle(fontSize: 14)),
                                Text(
                                    "เบอร์ผู้รับ: ${data['receiverPhone'] ?? '-'}",
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 4),
                                Text("[สถานะ]: ${data['status'] ?? 'ไม่มีสถานะ'}",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          if (!hasRider)
                            ElevatedButton(
                              onPressed: () => acceptJob(productId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8C42),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "รับงาน",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
