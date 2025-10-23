import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA64C),
        automaticallyImplyLeading: false,
        title: const Text(
          'receiver orders',
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
                  hintText: 'search',
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

            // 🧃 แสดงรายการสินค้าที่ต้องรับ
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
                      final data =
                          products[index].data() as Map<String, dynamic>;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE1C0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🖼 รูปภาพสินค้า
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  data['productImage'] != null &&
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
                                  Text(
                                    "ผู้รับ : ${data['receiverPhone'] ?? '-'}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "[1]: รอไรเดอร์มารับสินค้า",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
        // currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            // ถ้ากด "ส่งสินค้า"
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
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: "รับสินค้า",
          ),
        ],
      ),
    );
  }
}
