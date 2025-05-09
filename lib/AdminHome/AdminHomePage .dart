import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yala_tamrin_admin/PopularGround/helper.dart';
import 'package:yala_tamrin_admin/login/login.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int selectedIndex = 0;
  final List<String> pages = [
    "Dashboard",
    "Users",
    "Ground Management",
    "Add Venue",
    "Reports",
    "Settings"
  ];
  final String adminId = "";
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // القائمة الجانبية
          Container(
            width: 240,
            color: Colors.black,
            child: Column(
              children: [
                const DrawerHeader(
                  child: Center(
                    child: Text(
                      'يلا تمرين',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ...List.generate(pages.length, (index) {
                  return ListTile(
                    selected: selectedIndex == index,
                    selectedTileColor: Colors.grey[800],
                    leading: Icon(
                      _getIconForIndex(index),
                      color: Colors.white,
                    ),
                    title: Text(
                      pages[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      setState(() => selectedIndex = index);
                    },
                  );
                }),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.white),
                  title: const Text(
                    'الملف الشخصي',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => _showProfileDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: _signOut,
                ),
              ],
            ),
          ),

          // محتوى الصفحة الرئيسية
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pages[selectedIndex],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Expanded(child: _buildPageContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileDialog(BuildContext context) async {
    final profileData = await _loadAdminData();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: ProfileDialogContent(
              profileData: profileData,
              onSave: _saveAdminData,
              onSignOut: _signOut,
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadAdminData() async {
    try {
      final doc = await firestore.collection("admins").doc(adminId).get();
      return doc.data() ??
          {
            "name": "",
            "email": FirebaseAuth.instance.currentUser?.email ?? "",
            "phone": ""
          };
    } catch (e) {
      return {
        "name": "",
        "email": FirebaseAuth.instance.currentUser?.email ?? "",
        "phone": ""
      };
    }
  }

  Future<void> _saveAdminData(Map<String, dynamic> data) async {
    try {
      String? imageUrl;

      if (data['imageFile'] != null) {
        final file = data['imageFile'] as File;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('admin_profile_images')
            .child('$adminId.jpg');

        await storageRef.putFile(file);
        imageUrl = await storageRef.getDownloadURL();
      }

      await firestore.collection("admins").doc(adminId).set({
        "name": data["name"],
        "phone": data["phone"],
        "email": FirebaseAuth.instance.currentUser?.email ?? "",
        if (imageUrl != null) "imageUrl": imageUrl,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم حفظ البيانات بنجاح")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في الحفظ: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OneSignalLoginStyled()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في تسجيل الخروج: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildPageContent() {
    switch (selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildUsersPage();
      case 2:
        return AdminGroundManagement(); // صفحة إدارة الملاعب
      case 3:
        return AddVenueScreen(); // صفحة إدارة الملاعب
      case 4:
        return _buildReportsPage();
      case 5:
        return _buildSettingsPage();
      default:
        return const Center(child: Text("الصفحة غير متوفرة"));
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // بطاقات الإحصائيات
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard("المستخدمين", "1,234", Icons.people, Colors.blue),
              _buildStatCard(
                  "النشاط اليومي", "56", Icons.trending_up, Colors.green),
              _buildStatCard("المهام", "12", Icons.task, Colors.orange),
              _buildStatCard("الإشعارات", "5", Icons.notifications, Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          // آخر النشاطات
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "آخر النشاطات",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildActivityItem(
                      "تم تسجيل مستخدم جديد", "10 دقائق مضت", Icons.person_add),
                  _buildActivityItem(
                      "تم تحديث الإعدادات", "ساعة مضت", Icons.settings),
                  _buildActivityItem("تم إرسال إشعار جماعي", "3 ساعات مضت",
                      Icons.notifications),
                  _buildActivityItem(
                      "نسخة احتياطية جديدة", "يوم مضى", Icons.backup),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersPage() {
    return const Center(
      child: Text(
        "إدارة المستخدمين",
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildReportsPage() {
    return const Center(
      child: Text(
        "التقارير والإحصائيات",
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildSettingsPage() {
    return const Center(
      child: Text(
        "إعدادات النظام",
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  Icon(icon, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: Text(
        time,
        style: TextStyle(color: Colors.grey[600]),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.people;
      case 2:
        return Icons.sports_soccer;
      case 3:
        return Icons.add;
      case 4:
        return Icons.bar_chart;
      case 5:
        return Icons.settings;
      default:
        return Icons.circle;
    }
  }
}

class ProfileDialogContent extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onSignOut;

  const ProfileDialogContent({
    required this.profileData,
    required this.onSave,
    required this.onSignOut,
    super.key,
  });

  @override
  State<ProfileDialogContent> createState() => _ProfileDialogContentState();
}

class _ProfileDialogContentState extends State<ProfileDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController phoneController;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.profileData['name'] ?? '');
    phoneController =
        TextEditingController(text: widget.profileData['phone'] ?? '');
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage!)
                    : widget.profileData["imageUrl"] != null
                        ? NetworkImage(widget.profileData["imageUrl"])
                        : null,
                child: selectedImage == null &&
                        widget.profileData["imageUrl"] == null
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
              validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSave({
                    "name": nameController.text,
                    "phone": phoneController.text,
                    "imageFile": selectedImage,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("حفظ"),
            ),
          ],
        ),
      ),
    );
  }
}
