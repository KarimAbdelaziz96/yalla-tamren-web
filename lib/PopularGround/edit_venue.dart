part of 'helper.dart';

class EditVenueScreen extends StatefulWidget {
  final Map<String, dynamic> venueData;
  final String docId;

  const EditVenueScreen({
    Key? key,
    required this.venueData,
    required this.docId,
  }) : super(key: key);

  @override
  State<EditVenueScreen> createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends State<EditVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  final PopularGroundController _controller = Get.find<PopularGroundController>();

  Uint8List? _newMainImage;
  List<Uint8List> _newGalleryImages = [];
  Map<String, bool> _sports = {
    'كرة القدم': false,
    'كرة السلة': false,
    'التنس': false,
    'كرة الطائرة': false,
  };
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.venueData['name']);
    _locationController = TextEditingController(text: widget.venueData['location']);
    
    if (widget.venueData['sports'] != null) {
      final sportsData = widget.venueData['sports'] as Map<String, dynamic>;
      _sports.updateAll((key, value) => sportsData[key] ?? false);
    }
  }

  Future<void> _pickImage(bool isMain) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowCompression: true,
    );

    if (result != null && result.files.single.bytes != null) {
      Uint8List imageBytes = result.files.single.bytes!;
      setState(() {
        if (isMain) {
          _newMainImage = imageBytes;
        } else {
          _newGalleryImages.add(imageBytes);
        }
      });
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _newGalleryImages.removeAt(index);
    });
  }

  Future<void> _updateVenue() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar("خطأ", "الرجاء ملء جميع الحقول المطلوبة");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? mainImageUrl;
      if (_newMainImage != null) {
        mainImageUrl = await _controller.uploadVenueImage(_newMainImage!, widget.docId);
      }

      List<String> additionalImageUrls = [];
      if (_newGalleryImages.isNotEmpty) {
        for (var image in _newGalleryImages) {
          final url = await _controller.uploadVenueImage(image, widget.docId);
          additionalImageUrls.add(url);
        }
      }

      await FirebaseFirestore.instance.collection('Venues').doc(widget.docId).update({
        'name': _nameController.text,
        'location': _locationController.text,
        if (mainImageUrl != null) 'mainImage': mainImageUrl,
        'sports': _sports,
        if (additionalImageUrls.isNotEmpty) 
          'additionalImages': FieldValue.arrayUnion(additionalImageUrls),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar("تم", "تم تحديث بيانات الملعب بنجاح");
      Navigator.pop(context);
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء التحديث: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePreview(Uint8List? image, {double size = 100, bool isMain = false}) {
    return GestureDetector(
      onTap: () => _pickImage(isMain),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(image, fit: BoxFit.cover),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 30),
                    Text(isMain ? 'صورة رئيسية' : 'صورة إضافية'),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملعب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateVenue,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: "اسم الملعب",
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value!.isEmpty ? "مطلوب" : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: "الموقع",
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value!.isEmpty ? "مطلوب" : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("الصورة الرئيسية", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Center(
                              child: _buildImagePreview(
                                _newMainImage,
                                size: 200,
                                isMain: true,
                              ),
                            ),
                            if (widget.venueData['mainImage'] != null && _newMainImage == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: CachedNetworkImage(
                                  imageUrl: widget.venueData['mainImage'],
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text("صور إضافية", style: TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _pickImage(false),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._newGalleryImages.asMap().entries.map((entry) {
                                  return Stack(
                                    children: [
                                      _buildImagePreview(entry.value, size: 80),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, size: 16),
                                          onPressed: () => _removeGalleryImage(entry.key),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                if (widget.venueData['additionalImages'] != null)
                                  ...(widget.venueData['additionalImages'] as List).map((url) {
                                    return CachedNetworkImage(
                                      imageUrl: url,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    );
                                  }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("الرياضات المتاحة", style: TextStyle(fontWeight: FontWeight.bold)),
                            ..._sports.entries.map((e) => CheckboxListTile(
                              value: e.value,
                              title: Text(e.key),
                              onChanged: (val) => setState(() => _sports[e.key] = val ?? false),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateVenue,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text("حفظ التعديلات"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}