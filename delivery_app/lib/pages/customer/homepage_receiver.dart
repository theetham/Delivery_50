import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/pages/customer/Detail_receiver.dart';
import 'package:delivery_app/pages/customer/homepage_customer.dart';
import 'package:delivery_app/pages/login.dart';
import 'package:flutter/material.dart';

class HomepageReceiver extends StatefulWidget {
  final String phone;
  final String role;
  final String userId;

  const HomepageReceiver({
    super.key,
    required this.phone,
    required this.role,
    required this.userId,
  });

  @override
  State<HomepageReceiver> createState() => _HomepageReceiverState();
}

class _HomepageReceiverState extends State<HomepageReceiver> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  String searchText = "";

  Future<Map<String, String>> getRiderInfo(String? riderId) async {
    try {
      if (riderId == null || riderId.isEmpty) return {'name': '-', 'phone': '-'};
      final doc = await db.collection('Users').doc(riderId).get();
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

  Future<Map<String, String>> getSenderInfo(String? senderId) async {
    try {
      if (senderId == null || senderId.isEmpty) return {'name': '-', 'phone': '-'};
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
          'รายการสินค้าที่ฉันจะได้รับ',
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
                  const SnackBar(content: Text("ออกจากระบบสำเร็จ ✅")),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text('ออกจากระบบ')),
            ],
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // 🔍 ช่องค้นหา
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                border: Border.all(color: const Color(0xFFFFA64C)),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Color(0xFFFFA64C)),
                  hintText: 'ค้นหาชื่อสินค้า...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 10),

            // 🧃 รายการสินค้าที่ผู้รับจะได้รับ
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection("Products")
                    .where("receiverPhone", isEqualTo: widget.phone)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final products = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['productName'] ?? '')
                        .toString()
                        .toLowerCase();
                    return name.contains(searchText);
                  }).toList();

                  if (products.isEmpty) {
                    return const Center(
                      child: Text("ยังไม่มีรายการรับสินค้า 📦"),
                    );
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final data = products[index].data() as Map<String, dynamic>;

                      return FutureBuilder(
                        future: Future.wait([
                          getSenderInfo(data['senderId']),
                          getRiderInfo(data['riderId'])
                        ]),
                        builder: (context, AsyncSnapshot<List<Map<String, String>>> snapshotInfo) {
                          if (!snapshotInfo.hasData) {
                            return const SizedBox();
                          }

                          final senderInfo = snapshotInfo.data![0];
                          final riderInfo = snapshotInfo.data![1];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Detail_receiver(
                                    productData: data,
                                    senderName: senderInfo['name'] ?? '-',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE5CC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🖼 รูปภาพสินค้า
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

                                  // 📋 รายละเอียดสินค้า
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
                                        Text("ผู้ส่ง: ${senderInfo['name']}"),
                                        Text("เบอร์ผู้ส่ง: ${senderInfo['phone']}"),
                                        Text("ผู้รับ: ${data['receiverName'] ?? '-'}"),
                                        Text("เบอร์ผู้รับ: ${data['receiverPhone'] ?? '-'}"),
                                        Text("ไรเดอร์: ${riderInfo['name']}"),
                                        Text("เบอร์ไรเดอร์: ${riderInfo['phone']}"),
                                        const SizedBox(height: 4),
                                        Text(
                                          "[สถานะ]: ${data['status'] ?? '-'}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: (data['status'] == 'จัดส่งสำเร็จ ✅')
                                                ? Colors.green
                                                : Colors.redAccent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
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
            ),
          ],
        ),
      ),

      // ⚙️ bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFF8C42),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomepageCustomer(
                  phone: widget.phone,
                  role: widget.role,
                  userId: widget.userId,
                ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.send), label: "ส่งสินค้า"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "รับสินค้า"),
        ],
      ),
    );
  }
}
