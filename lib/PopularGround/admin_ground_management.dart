part of 'helper.dart';

class AdminGroundManagement extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الملاعب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddVenueScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('Venues')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('حدث خطأ: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_soccer, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد ملاعب مسجلة',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddVenueScreen()),
                      ),
                      child: const Text('إضافة ملعب جديد'),
                    ),
                  ],
                ),
              );
            }

            return _buildVenuesGrid(snapshot.data!.docs);
          },
        ),
      ),
    );
  }

  Widget _buildVenuesGrid(List<QueryDocumentSnapshot> venues) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 3
            : constraints.maxWidth > 800
                ? 2
                : 1;

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85, // تعديل النسبة لتحسين الشكل
          ),
          itemCount: venues.length,
          itemBuilder: (context, index) {
            final venue = venues[index];
            return _VenueCard(venue: venue);
          },
        );
      },
    );
  }
}

class _VenueCard extends StatelessWidget {
  final QueryDocumentSnapshot venue;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  _VenueCard({Key? key, required this.venue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = venue.data() as Map<String, dynamic>;
    final id = venue.id;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // صورة الملعب (تم تحسينها)
          AspectRatio(
            aspectRatio: 16 / 9, // نسبة ثابتة للصور
            child: data['mainImage'] != null
                ? _buildNetworkImage(data['mainImage'])
                : _buildPlaceholder(),
          ),

          // معلومات الملعب
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اسم الملعب وحالته
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['name'] ?? 'بدون اسم',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(data['adminApproved'] == true),
                  ],
                ),

                const SizedBox(height: 8),

                // موقع الملعب
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        data['location'] ?? 'غير محدد',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // أزرار التحكم
                _buildActionButtons(context, data, id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(),
      fadeInDuration: const Duration(milliseconds: 300),
      memCacheHeight: 300, // تحسين الذاكرة المؤقتة
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.sports_soccer, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatusChip(bool isApproved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isApproved
            ? Colors.green.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isApproved ? 'مفعل' : 'قيد المراجعة',
        style: TextStyle(
          color: isApproved ? Colors.green : Colors.orange,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, Map<String, dynamic> data, String id) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 22),
          onPressed: () => _navigateToEdit(context, data, id),
          tooltip: 'تعديل',
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 22, color: Colors.red),
          onPressed: () => _confirmDelete(context, id),
          tooltip: 'حذف',
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: data['adminApproved'] == true,
            onChanged: (value) => _toggleStatus(context, id, value),
            activeColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleStatus(
      BuildContext context, String venueId, bool newStatus) async {
    try {
      await _firestore.collection('Venues').doc(venueId).update({
        'adminApproved': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'تم تفعيل الملعب' : 'تم تعطيل الملعب'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, String venueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الملعب؟ سيتم حذف جميع البيانات المرتبطة به.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // حذف الصور من التخزين
        final storageRef = _storage.ref().child('venues/$venueId');
        await storageRef.listAll().then((listResult) {
          return Future.wait(listResult.items.map((ref) => ref.delete()));
        });

        // حذف المستند من Firestore
        await _firestore.collection('Venues').doc(venueId).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الملعب بنجاح'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حذف الملعب: ${e.toString()}'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _navigateToEdit(
      BuildContext context, Map<String, dynamic> data, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVenueScreen(venueData: data, docId: id),
      ),
    );
  }
}