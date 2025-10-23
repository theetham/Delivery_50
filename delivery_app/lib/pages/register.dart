import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'select_location_page.dart'; // ต้องมีไฟล์นี้ในโฟลเดอร์เดียวกัน

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullnameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final passCtl = TextEditingController();
  final vehicleCtl = TextEditingController();

  String selectedRole = "customer"; // default
  String imageBase64 = '';
  String riderImageBase64 = '';
  String vehicleImageBase64 = '';

  double? latitude;
  double? longitude;
  double? latitude2;
  double? longitude2;

  /// ✅ สมัครสมาชิก
  Future<void> registerUser() async {
    try {
      if (fullnameCtl.text.isEmpty ||
          phoneCtl.text.isEmpty ||
          passCtl.text.isEmpty) {
        _showSnackBar("กรุณากรอกข้อมูลให้ครบถ้วน ❗");
        return;
      }

      var db = FirebaseFirestore.instance;

      // เช็คเบอร์ซ้ำเฉพาะ customer เท่านั้น
      if (selectedRole == "customer") {
        var existing = await db
            .collection("Users")
            .where("phone", isEqualTo: phoneCtl.text)
            .get();

        if (existing.docs.isNotEmpty) {
          _showSnackBar("เบอร์โทรนี้ถูกใช้งานแล้ว ❌");
          return;
        }
      }

      Map<String, dynamic> data = {
        "fullname": fullnameCtl.text,
        "phone": phoneCtl.text,
        "password": passCtl.text, // (ควรเข้ารหัสภายหลัง)
        "role": selectedRole,
        "createdAt": FieldValue.serverTimestamp(),
      };

      // 📍 ถ้าเป็นลูกค้า
      if (selectedRole == "customer") {
        if (latitude == null || longitude == null) {
          _showSnackBar("กรุณาเลือกตำแหน่งหลักจากแผนที่ 🌍");
          return;
        }

        data.addAll({
          "location": {"lat": latitude, "lng": longitude},
          "location2": (latitude2 != null && longitude2 != null)
              ? {"lat": latitude2, "lng": longitude2}
              : null,
          "image": imageBase64,
        });
      }

      // 🛵 ถ้าเป็นไรเดอร์
      if (selectedRole == "rider") {
        if (vehicleCtl.text.isEmpty ||
            riderImageBase64.isEmpty ||
            vehicleImageBase64.isEmpty) {
          _showSnackBar("กรุณากรอกข้อมูลและเลือกรูปให้ครบถ้วน ❗");
          return;
        }

        data.addAll({
          "vehicleNumber": vehicleCtl.text,
          "riderImage": riderImageBase64,
          "vehicleImage": vehicleImageBase64,
        });
      }

      await db.collection("Users").add(data);
      _showSnackBar("สมัครสมาชิกสำเร็จ ✅");

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar("เกิดข้อผิดพลาด ❌: $e");
    }
  }

  /// 📸 เลือกรูป
  Future<void> pickImage(String type) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Img = base64Encode(bytes);

        if (!mounted) return;

        setState(() {
          if (type == "customer") imageBase64 = base64Img;
          if (type == "riderImage") riderImageBase64 = base64Img;
          if (type == "vehicleImage") vehicleImageBase64 = base64Img;
        });
      }
    } catch (e) {
      _showSnackBar("เลือกรูปไม่สำเร็จ ❌");
    }
  }

  /// SnackBar helper
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔸 Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(color: Color(0xFFFF8C42)),
              child: const Center(
                child: Text(
                  "ลงทะเบียน",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🔸 เลือกบทบาท
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: _inputDecoration("เลือกบทบาท"),
                    items: const [
                      DropdownMenuItem(
                        value: "customer",
                        child: Text("Customer"),
                      ),
                      DropdownMenuItem(
                        value: "rider",
                        child: Text("Rider"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedRole = value!);
                    },
                  ),
                  const SizedBox(height: 12),

                  // 🔸 ข้อมูลทั่วไป
                  TextField(
                    controller: fullnameCtl,
                    decoration: _inputDecoration("ชื่อ-สกุล"),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: phoneCtl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration("เบอร์โทรศัพท์"),
                  ),
                  const SizedBox(height: 12),

                  // 🔸 Customer
                  if (selectedRole == "customer") ...[
                    // เลือกตำแหน่งหลัก
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SelectLocationPage(),
                          ),
                        );

                        if (result != null && mounted) {
                          setState(() {
                            latitude = result['lat'];
                            longitude = result['lng'];
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white,
                          border:
                              Border.all(color: const Color(0xFFFF8C42), width: 3),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map, color: Color(0xFFFF8C42)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                latitude == null
                                    ? "เลือกตำแหน่งหลักจากแผนที่"
                                    : "ตำแหน่งหลัก: (${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)})",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // เลือกตำแหน่งสำรอง
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SelectLocationPage(),
                          ),
                        );

                        if (result != null && mounted) {
                          setState(() {
                            latitude2 = result['lat'];
                            longitude2 = result['lng'];
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white,
                          border:
                              Border.all(color: const Color(0xFFFF8C42), width: 3),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map_outlined, color: Color(0xFFFF8C42)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                latitude2 == null
                                    ? "เลือกตำแหน่งสำรองจากแผนที่"
                                    : "ตำแหน่งสำรอง: (${latitude2!.toStringAsFixed(5)}, ${longitude2!.toStringAsFixed(5)})",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () => pickImage("customer"),
                      child: UploadButton(
                        icon: Icons.image,
                        label: imageBase64.isEmpty
                            ? "เลือกรูปโปรไฟล์ลูกค้า"
                            : "เลือกรูปแล้ว ✅",
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 🔸 Rider
                  if (selectedRole == "rider") ...[
                    TextField(
                      controller: vehicleCtl,
                      decoration: _inputDecoration("หมายเลขยานพาหนะ"),
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () => pickImage("riderImage"),
                      child: UploadButton(
                        icon: Icons.person,
                        label: riderImageBase64.isEmpty
                            ? "เลือกรูปไรเดอร์"
                            : "เลือกรูปแล้ว ✅",
                      ),
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () => pickImage("vehicleImage"),
                      child: UploadButton(
                        icon: Icons.directions_bike,
                        label: vehicleImageBase64.isEmpty
                            ? "เลือกรูปรถ/ทะเบียนรถ"
                            : "เลือกรูปแล้ว ✅",
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 🔸 Password
                  TextField(
                    controller: passCtl,
                    obscureText: true,
                    decoration: _inputDecoration("รหัสผ่าน"),
                  ),
                  const SizedBox(height: 25),

                  // 🔸 ปุ่มสมัครสมาชิก
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C42),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "สมัครสมาชิก",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🔸 ลิงก์เข้าสู่ระบบ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("มีบัญชีอยู่แล้ว? "),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "เข้าสู่ระบบ",
                          style: TextStyle(
                            color: Color(0xFFFF8C42),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ input style เดียวกัน
  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFFF8C42), width: 3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFFF8C42), width: 2.5),
        ),
        filled: true,
        fillColor: Colors.white,
      );
}

/// ปุ่มอัปโหลดรูป
class UploadButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const UploadButton({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFF8C42), width: 3),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF8C42)),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
