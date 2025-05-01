import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:yala_tamrin_admin/Ground/GroundModel.dart';

class GroundController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إضافة ملعب جديد
  Future<void> addGround(GroundModel ground) async {
    try {
      await _firestore.collection('grounds').add(ground.toMap());
      Get.snackbar('Success', 'تمت إضافة الملعب بنجاح!');
    } catch (e) {
      Get.snackbar('Error', 'فشل في إضافة الملعب: $e');
    }
  }

  // جلب جميع الملاعب
  Stream<List<GroundModel>> getGrounds() {
    return _firestore.collection('grounds').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return GroundModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // تحديث ملعب
  Future<void> updateGround(GroundModel ground) async {
    try {
      await _firestore.collection('grounds').doc(ground.id).update(ground.toMap());
      Get.snackbar('Success', 'تم تحديث الملعب بنجاح!');
    } catch (e) {
      Get.snackbar('Error', 'فشل في تحديث الملعب: $e');
    }
  }

  // حذف ملعب
  Future<void> deleteGround(String groundId) async {
    try {
      await _firestore.collection('grounds').doc(groundId).delete();
      Get.snackbar('Success', 'تم حذف الملعب بنجاح!');
    } catch (e) {
      Get.snackbar('Error', 'فشل في حذف الملعب: $e');
    }
  }
}