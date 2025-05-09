part of "helper.dart";

class PopularGroundController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadVenueImage(Uint8List imageBytes, String venueId) async {
    try {
      String imageName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = _storage.ref().child('venues/$venueId/$imageName');

      UploadTask uploadTask = storageRef.putData(imageBytes as Uint8List);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload image: ${e.toString()}');
      throw e;
    }
  }

  Future<void> addNewVenue({
    required String name,
    required String location,
    required Uint8List mainImage,
    required Map<String, bool> sports,
    List<Uint8List>? additionalImages,
  }) async {
    try {
      DocumentReference venueRef = _firestore.collection('Venues').doc();
      String mainImageUrl = await uploadVenueImage(mainImage, venueRef.id);

      List<String> additionalImageUrls = [];
      if (additionalImages != null) {
        for (var imageBytes in additionalImages) {
          String url = await uploadVenueImage(imageBytes, venueRef.id);
          additionalImageUrls.add(url);
        }
      }

      await venueRef.set({
        'name': name,
        'location': location,
        'mainImage': mainImageUrl,
        'additionalImages': additionalImageUrls,
        'sports': sports,
        'rating': 0,
        'isPopular': false,
        'adminApproved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Success', 'Venue added successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add venue: ${e.toString()}');
      throw e;
    }
  }
}


class AddVenueScreen extends StatefulWidget {
  const AddVenueScreen({Key? key}) : super(key: key);

  @override
  State<AddVenueScreen> createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends State<AddVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final PopularGroundController _controller = Get.find<PopularGroundController>();

  Uint8List? _mainImage;
  List<Uint8List> _galleryImages = [];
  Map<String, bool> _sports = {
    'كرة القدم': false,
    'كرة السلة': false,
    'التنس': false,
    'كرة الطائرة': false,
  };

  bool _isLoading = false;

  Future<void> _pickImage(bool isMain) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowCompression: true,
    );

    if (result != null && result.files.single.bytes != null) {
      Uint8List imageBytes = result.files.single.bytes!;
      if (isMain) {
        setState(() => _mainImage = imageBytes);
      } else {
        setState(() => _galleryImages.add(imageBytes));
      }
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImages.removeAt(index);
    });
  }

  Future<void> _submitVenue() async {
    if (!_formKey.currentState!.validate() || _mainImage == null) {
      Get.snackbar("خطأ", "الرجاء ملء جميع الحقول واختيار صورة رئيسية");
      return;
    }

    Map<String, bool> selectedSports =
        _sports..removeWhere((key, value) => value == false);

    if (selectedSports.isEmpty) {
      Get.snackbar("تنبيه", "اختر نوع واحد على الأقل من الرياضات");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _controller.addNewVenue(
        name: _nameController.text,
        location: _locationController.text,
        mainImage: _mainImage!,
        sports: selectedSports,
        additionalImages: _galleryImages,
      );
      Get.snackbar("تم", "تم إضافة الملعب بنجاح");

      // Reset
      _formKey.currentState?.reset();
      _nameController.clear();
      _locationController.clear();
      setState(() {
        _mainImage = null;
        _galleryImages.clear();
        _sports.updateAll((key, value) => false);
      });
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء الإرسال");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _imagePreview(Uint8List? img, {double size = 100}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: img != null
          ? Image.memory(img, width: size, height: size, fit: BoxFit.cover)
          : Container(
              width: size,
              height: size,
              color: Colors.grey[200],
              child: Icon(Icons.add_a_photo, size: 30),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("إضافة ملعب جديد")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(labelText: "اسم الملعب"),
                              validator: (v) => v!.isEmpty ? "مطلوب" : null,
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _locationController,
                              decoration: InputDecoration(labelText: "الموقع"),
                              validator: (v) => v!.isEmpty ? "مطلوب" : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    Card(
                      child: Column(
                        children: [
                          ListTile(title: Text("الصورة الرئيسية")),
                          GestureDetector(
                            onTap: () => _pickImage(true),
                            child: _imagePreview(_mainImage),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text("صور إضافية"),
                            trailing: IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => _pickImage(false),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _galleryImages.asMap().entries.map((entry) {
                                int index = entry.key;
                                Uint8List image = entry.value;
                                return Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    _imagePreview(image, size: 80),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _removeGalleryImage(index),
                                        child: CircleAvatar(
                                          backgroundColor: Colors.red,
                                          radius: 10,
                                          child: Icon(Icons.close, size: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    Card(
                      child: Column(
                        children: [
                          ListTile(title: Text("الرياضات المتوفرة")),
                          ..._sports.entries.map(
                            (e) => CheckboxListTile(
                              value: e.value,
                              title: Text(e.key),
                              onChanged: (val) {
                                setState(() => _sports[e.key] = val ?? false);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _submitVenue,
                      icon: Icon(Icons.save),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text("حفظ الملعب"),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
