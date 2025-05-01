import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yala_tamrin_admin/Ground/GroundController.dart';
import 'package:yala_tamrin_admin/Ground/GroundModel.dart';

class AdminDashboard extends StatelessWidget {
  final GroundController _controller = Get.put(GroundController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم الملاعب'),
      ),
 body: StreamBuilder<List<GroundModel>>(
  stream: _controller.getGrounds(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('حدث خطأ: ${snapshot.error}'));
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(child: Text('لا توجد ملاعب متاحة'));
    }

    final grounds = snapshot.data!;
    return ListView.builder(
      itemCount: grounds.length,
      itemBuilder: (context, index) {
        final ground = grounds[index];
        return ListTile(
          title: Text(ground.name),
          subtitle: Text(ground.location),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  _showEditGroundDialog(ground);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _controller.deleteGround(ground.id!);
                },
              ),
            ],
          ),
        );
      },
    );
  },
),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddGroundDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

void _showAddGroundDialog() {
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  Get.dialog(
    AlertDialog(
      title: Text('إضافة ملعب جديد'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'اسم الملعب'),
          ),
          TextField(
            controller: locationController,
            decoration: InputDecoration(labelText: 'الموقع'),
          ),
          TextField(
            controller: phoneController,
            decoration: InputDecoration(labelText: 'الهاتف'),
          ),
          TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'البريد الإلكتروني'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: Text('إلغاء'),
        ),
        TextButton(
          onPressed: () {
            final ground = GroundModel(
              name: nameController.text,
              location: locationController.text,
              phone: phoneController.text,
              email: emailController.text,
            );
            _controller.addGround(ground);
            Get.back();
          },
          child: Text('إضافة'),
        ),
      ],
    ),
  );
}
 
  void _showEditGroundDialog(GroundModel ground) {
    final nameController = TextEditingController(text: ground.name);
    final locationController = TextEditingController(text: ground.location);
    final phoneController = TextEditingController(text: ground.phone);
    final emailController = TextEditingController(text: ground.email);

    Get.dialog(
      AlertDialog(
        title: Text('تعديل الملعب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'اسم الملعب'),
            ),
            TextField(
              controller: locationController,
              decoration: InputDecoration(labelText: 'الموقع'),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'الهاتف'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'البريد الإلكتروني'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final updatedGround = GroundModel(
                id: ground.id,
                name: nameController.text,
                location: locationController.text,
                phone: phoneController.text,
                email: emailController.text,
              );
              _controller.updateGround(updatedGround);
              Get.back();
            },
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }
}