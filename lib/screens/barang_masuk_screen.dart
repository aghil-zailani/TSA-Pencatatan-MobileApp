import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class FormFieldConfig {
  final String fieldName;
  final String labelDisplay;
  final String inputType;
  final bool isRequired;
  final int fieldOrder;

  FormFieldConfig({
    required this.fieldName,
    required this.labelDisplay,
    required this.inputType,
    required this.isRequired,
    required this.fieldOrder,
  });

  factory FormFieldConfig.fromJson(Map<String, dynamic> json) {
    return FormFieldConfig(
      fieldName: json['field_name'] as String? ?? 'UNKNOWN_FIELD',
      labelDisplay: json['label_display'] as String? ?? 'Label Tidak Ditemukan',
      inputType: json['input_type'] as String? ?? 'text',
      isRequired: (json['is_required'] == 1 || json['is_required'] == true),
      fieldOrder: json['field_order'] as int? ?? 999,
    );
  }

  IconData getIconData() {
    switch (fieldName) {
      case 'nama_barang': return Icons.label_outline;
      case 'tipe_barang': return Icons.category_outlined;
      case 'jumlah_barang': return Icons.numbers_outlined;
      case 'satuan': return Icons.straighten_outlined;
      case 'jenis_barang': return Icons.category_outlined;
      case 'kondisi': return Icons.health_and_safety_outlined;
      case 'berat': return Icons.scale_outlined;
      // case 'tanggal_kadaluarsa': return Icons.calendar_today_outlined;
      case 'media': return Icons.science_outlined;
      case 'ukuran_barang': return Icons.square_foot_outlined;
      case 'panjang': return Icons.straighten;
      case 'lebar': return Icons.width_wide_outlined;
      case 'tinggi': return Icons.height_outlined;
      case 'merek': return Icons.branding_watermark_outlined;
      default: return Icons.help_outline;
    }
  }
}

class BarangMasukScreen extends StatefulWidget {
  final String? initialType;

  const BarangMasukScreen({Key? key, this.initialType}) : super(key: key);

  @override
  _BarangMasukScreenState createState() => _BarangMasukScreenState();
}

class _BarangMasukScreenState extends State<BarangMasukScreen> {
  final Map<String, TextEditingController> _controllers = {};
  String _selectedType = 'APAR';

  // Enhanced Blue Color Palette
  final Color primaryBlue = Color(0xFF1976D2);
  final Color lightBlue = Color(0xFF42A5F5);
  final Color darkBlue = Color(0xFF0D47A1);
  final Color accentBlue = Color(0xFF03DAC6);
  final Color backgroundBlue = Color(0xFFF3F8FF);
  final Color surfaceBlue = Color(0xFFE3F2FD);

  List<FormFieldConfig> _currentFormConfigs = [];
  final Map<String, String?> _selectedDropdownValues = {};
  List<String> _availableCategories = [];

  bool _isProcessingOcr = false;
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    _fetchAvailableCategories().then((_) {
      if (_selectedType.isNotEmpty) {
        _fetchFormData(_selectedType);
      }
    });
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    setState(() { _isProcessingOcr = true; });
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? imageFile = await picker.pickImage(source: source);

      if (imageFile == null) {
        setState(() { _isProcessingOcr = false; });
        return;
      }

      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        setState(() { _isProcessingOcr = false; });
        return;
      }
      final grayscaleImage = img.grayscale(originalImage);
      final processedBytes = img.encodeJpg(grayscaleImage);
      final processedFile = await File(imageFile.path).writeAsBytes(processedBytes);

      final inputImage = InputImage.fromFile(processedFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      _parseOcrTextAndFillForm(recognizedText);

    } catch (e) {
      print("Error during OCR process: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses gambar.'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isProcessingOcr = false; });
    }
  }

  // --- FUNGSI PARSING OCR YANG BARU ---

  void _parseOcrTextAndFillForm(RecognizedText recognizedText) {
    final List<String> ocrLines = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        ocrLines.add(line.text);
      }
    }
    print("--- Teks Hasil OCR (per baris) ---\n${ocrLines.join('\n')}\n--------------------");

    final Map<String, String> extractedData = _extractDataFromOCR(ocrLines);

    extractedData.forEach((key, value) {
      if (value.isNotEmpty) {
        if (_controllers.containsKey(key)) {
          _controllers[key]?.text = value;
        } else if (_selectedDropdownValues.containsKey(key)) {
          final options = _getManualDropdownOptions(key);
          for (var option in options) {
            if (option.toLowerCase() == value.toLowerCase()) {
              _selectedDropdownValues[key] = option;
              break;
            }
          }
        }
      }
    });

    setState(() {});
  }

  // --- LOGIKA OCR CANGGIH ---
  static const knownBrands = [
    'SERVVO', 'YAMATO', 'SEMPATI', 'NOTIFIER', 'HOCHIKI', 'CHUBB', 'TYCO', 'ANGUS FIRE', 'FM 200 SUPRESSION'
  ];

  int levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<List<int>> matrix =
    List.generate(s.length + 1, (_) => List.filled(t.length + 1, 0));

    for (var i = 0; i <= s.length; i++) matrix[i][0] = i;
    for (var j = 0; j <= t.length; j++) matrix[0][j] = j;

    for (var i = 1; i <= s.length; i++) {
      for (var j = 1; j <= t.length; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[s.length][t.length];
  }

  String? detectClosestBrand(String line) {
    String cleaned = line.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    int threshold = 2; // toleransi typo: 2 huruf beda

    for (final brand in knownBrands) {
      int distance = levenshtein(cleaned, brand);
      if (distance <= threshold) return brand;
    }
    return null;
  }

  Map<String, String> _extractDataFromOCR(List<String> ocrLines) {
    final result = <String, String>{};
    final fullText = ocrLines.join(' ').toUpperCase();

    // --- 1. Deteksi Berat & Satuan ---
    final beratRegex = RegExp(r'(\d+)\s*(KG|G|GRAM|L|LTR|LITER)', caseSensitive: false);
    final matchBerat = beratRegex.firstMatch(fullText);
    if (matchBerat != null) {
      result['berat'] = matchBerat.group(1)!;
      result['satuan'] = matchBerat.group(2)!.toUpperCase();
      print("Ditemukan -> berat: ${result['berat']} ${result['satuan']}");
    }

    // --- 2. Deteksi Media ---
    final mediaRegex = RegExp(r'\b(ABC|CO2|POWDER|FOAM)\b', caseSensitive: false);
    final matchMedia = mediaRegex.firstMatch(fullText);
    if (matchMedia != null) {
      result['media'] = matchMedia.group(1)!.toUpperCase();
      print("Ditemukan -> media: ${result['media']}");
    }

    // --- 3. Deteksi Tipe Barang (APAR, HYDRANT, dll) ---
    if (fullText.contains('EXTINGUISHER') || fullText.contains('APAR')) {
      result['tipe_barang'] = 'APAR';
      print("Ditemukan -> tipe_barang: APAR");
    } else if (fullText.contains('HYDRANT')) {
      result['tipe_barang'] = 'Hydrant';
      print("Ditemukan -> tipe_barang: Hydrant");
    }

    // --- 4. PERBAIKAN: Deteksi Merek & Nama Barang dengan Levenshtein ---
    for (final line in ocrLines) {
      final cleanLine = line.trim().toUpperCase();
      if (cleanLine.isNotEmpty && cleanLine.length > 2) {
        final detectedBrand = detectClosestBrand(cleanLine);
        if (detectedBrand != null) {
          result['nama_barang'] = detectedBrand;
          result['merek'] = detectedBrand;
          print("Ditemukan -> nama_barang (dari merek): $detectedBrand");
          break; // Hentikan pencarian setelah merek ditemukan
        }
      }
    }

    if (result['nama_barang'] == null || result['nama_barang']!.isEmpty) {
      for (final brand in knownBrands) {
        final distance = levenshtein(fullText.replaceAll(' ', ''), brand.replaceAll(' ', ''));
        if (distance <= 3) {
          result['nama_barang'] = brand;
          result['merek'] = brand;
          print("Fallback fuzzy brand detection: $brand");
          break;
        }
      }
    }

    return result;
  }

  Future<void> _fetchAvailableCategories() async {
    const String baseUrl = 'http://192.168.56.96:8000/api';
    try {
      final response = await http.get(Uri.parse('$baseUrl/master-data/category_name'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> categories = data['categories'];
        setState(() {
          _availableCategories = categories
              .cast<String>()
              .where((c) => c != 'Sparepart' && c != 'Barang Keluar')
              .toList();

          if (!_availableCategories.contains(_selectedType)) {
            _selectedType = _availableCategories.isNotEmpty ? _availableCategories.first : '';
          }
        });

      } else {
        print('Gagal memuat kategori: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetch kategori: $e');
    }
  }

  Future<void> _fetchFormData(String formType) async {
    const String baseUrl = 'http://192.168.56.96:8000/api';

    setState(() {
      _currentFormConfigs = [];
      _selectedDropdownValues.clear();
      _controllers.forEach((key, controller) => controller.dispose());
      _controllers.clear();
    });

    try {
      final configResponse = await http.get(Uri.parse('$baseUrl/form-configs/$formType'));

      if (configResponse.statusCode == 200) {
        List<dynamic> configData = json.decode(configResponse.body);
        List<FormFieldConfig> fetchedConfigs = configData.map((json) => FormFieldConfig.fromJson(json)).toList();
        fetchedConfigs.sort((a, b) => a.fieldOrder.compareTo(b.fieldOrder));

        setState(() {
          _currentFormConfigs = fetchedConfigs;
          for (var config in _currentFormConfigs) {
            if (config.inputType == 'dropdown' || _isManualDropdown(config.fieldName)) {
              _selectedDropdownValues[config.fieldName] = null;
            } else {
              _controllers[config.fieldName] = TextEditingController();
            }
          }
        });
      } else {
        setState(() {
          _currentFormConfigs = [
            FormFieldConfig(
              fieldName: 'error',
              labelDisplay: 'Gagal Memuat Form (Status ${configResponse.statusCode})',
              inputType: 'text',
              isRequired: true,
              fieldOrder: 0,
            )
          ];
        });
      }
    } catch (e) {
      setState(() {
        _currentFormConfigs = [
          FormFieldConfig(
            fieldName: 'error',
            labelDisplay: 'Gagal Memuat Form: ${e.toString()}',
            inputType: 'text',
            isRequired: true,
            fieldOrder: 0,
          )
        ];
      });
    }
  }

  bool _isManualDropdown(String fieldName) {
    return fieldName == 'satuan' || fieldName == 'jenis_barang' || fieldName == 'kondisi';
  }

  List<String> _getManualDropdownOptions(String fieldName) {
    if (fieldName == 'satuan') {
      return ['Kg', 'Pcs', 'Meter', 'Liter'];
    } else if (fieldName == 'jenis_barang'){
      return ['Foam', 'CO2', 'ABC Powder', 'Karbon Dioksida'];
    } else if (fieldName == 'kondisi'){
      return ['Bagus', 'Rusak', 'Expired'];
    }
    return [];
  }

  Future<List<String>> _fetchDropdownOptions(String fieldName) async {
    const String baseUrl = 'http://192.168.56.96:8000/api';
    try {
      final response = await http.get(Uri.parse('$baseUrl/master-data/$fieldName'));
      if (response.statusCode == 200) {
        final List<dynamic> options = json.decode(response.body);
        return options.cast<String>();
      } else {
        print('Gagal ambil opsi $fieldName: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetch opsi dropdown $fieldName: $e');
      return [];
    }
  }

  void _saveData() async {
    Map<String, dynamic> dataToSave = {
      'tipe_barang_kategori': _selectedType,
    };

    String? namaBarang;

    for (var config in _currentFormConfigs) {
      if (config.fieldName == 'tipe_barang') {
        continue;
      }

      dynamic value;
      if (config.inputType == 'dropdown' || _isManualDropdown(config.fieldName)) {
        value = _selectedDropdownValues[config.fieldName];
      } else {
        value = _controllers[config.fieldName]?.text;
      }

      if (config.fieldName == 'jumlah_barang') {
        int? parsed = int.tryParse(value ?? '');
        if (parsed == null || parsed <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Jumlah Barang harus berupa angka valid!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        value = parsed;
      }

      if (config.isRequired && (value == null || value.toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${config.labelDisplay} wajib diisi!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (config.fieldName == 'nama_barang') {
        namaBarang = value;
      }

      dataToSave[config.fieldName] = value;
    }

    if (_selectedType != 'Sparepart' && _selectedType != 'Barang Keluar') {
      dataToSave['tipe_barang'] = 'Barang Jadi';
    }

    if (namaBarang == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama barang wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2) Cek increment dari API
    const String baseUrl = 'http://192.168.56.96:8000/api';

    // 3) Kirim ke DB
    final postResponse = await http.post(
      Uri.parse('$baseUrl/pengajuan-barangs'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(dataToSave),
    );

    // BLOK KODE BARU DENGAN PENANGANAN ERROR DETAIL
    if (postResponse.statusCode == 200 || postResponse.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      // Optional: Kosongkan form setelah berhasil
      _controllers.forEach((key, controller) => controller.clear());
      _selectedDropdownValues.clear();
      setState(() {});

    } else {
      String errorMessage = 'Gagal menyimpan data. Status: ${postResponse.statusCode}';

      // Cek jika ini adalah error validasi dari Laravel
      if (postResponse.statusCode == 422) {
        print("--- VALIDATION ERROR ---");
        print(postResponse.body);
        print("------------------------");

        try {
          final responseBody = json.decode(postResponse.body);
          final Map<String, dynamic> errors = responseBody['errors'];

          // Ambil NAMA FIELD dan PESAN ERROR dari response Laravel
          final firstEntry = errors.entries.first;
          final fieldName = firstEntry.key; // -> Ini nama fieldnya
          final errorText = firstEntry.value[0]; // -> Ini pesan errornya

          // Gabungkan keduanya untuk pesan yang jauh lebih jelas
          errorMessage = "Error pada field '$fieldName': $errorText";

        } catch (e) {
          errorMessage = "Terjadi error validasi, cek konsol debug.";
        }
      } else {
        // Untuk error server lainnya (spt: 500)
        print("--- SERVER ERROR ---");
        print(postResponse.body);
        print("--------------------");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Input Barang Masuk',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola data barang masuk inventori',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: surfaceBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.category,
                  color: primaryBlue,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Kategori Barang',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: surfaceBlue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedType.isNotEmpty ? _selectedType : null,
              decoration: InputDecoration(
                labelText: 'Pilih Kategori',
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.all(12),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    color: primaryBlue,
                    size: 20,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: _availableCategories
                  .map((value) => DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: darkBlue,
                  ),
                ),
              ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedType = newValue!;
                  _fetchFormData(_selectedType);
                });
              },
              dropdownColor: Colors.white,
              iconEnabledColor: primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(FormFieldConfig config) {
    if (config.inputType == 'dropdown' || _isManualDropdown(config.fieldName)) {
      List<String> options = _isManualDropdown(config.fieldName)
          ? _getManualDropdownOptions(config.fieldName)
          : [];

      return Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: FutureBuilder<List<String>>(
          future: options.isEmpty ? _fetchDropdownOptions(config.fieldName) : Future.value(options),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 12),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: surfaceBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        config.getIconData(),
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        backgroundColor: surfaceBlue,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                      ),
                    ),
                  ],
                ),
              );
            }
            return DropdownButtonFormField<String>(
              value: _selectedDropdownValues[config.fieldName],
              decoration: InputDecoration(
                labelText: config.isRequired ? '${config.labelDisplay} *' : config.labelDisplay,
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.all(12),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: surfaceBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    config.getIconData(),
                    color: primaryBlue,
                    size: 20,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: snapshot.data!
                  .map((option) => DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: darkBlue,
                  ),
                ),
              ))
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDropdownValues[config.fieldName] = newValue;
                });
              },
              dropdownColor: Colors.white,
              iconEnabledColor: primaryBlue,
            );
          },
        ),
      );
    } else if (config.inputType == 'date') {
      return Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _controllers[config.fieldName],
          readOnly: true,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: darkBlue,
          ),
          decoration: InputDecoration(
            labelText: config.isRequired ? '${config.labelDisplay} *' : config.labelDisplay,
            labelStyle: TextStyle(
              fontFamily: 'Poppins',
              color: primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: EdgeInsets.all(12),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surfaceBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                config.getIconData(),
                color: primaryBlue,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onTap: () => _selectDate(context, _controllers[config.fieldName]!),
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _controllers[config.fieldName],
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: darkBlue,
          ),
          decoration: InputDecoration(
            labelText: config.isRequired ? '${config.labelDisplay} *' : config.labelDisplay,
            labelStyle: TextStyle(
              fontFamily: 'Poppins',
              color: primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: EdgeInsets.all(12),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surfaceBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                config.getIconData(),
                color: primaryBlue,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: config.inputType == 'number' ? TextInputType.number : TextInputType.text,
        ),
      );
    }
  }

  Widget _buildOcrCard() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [ BoxShadow(color: primaryBlue.withOpacity(0.1), blurRadius: 16, offset: Offset(0, 4)) ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: surfaceBlue, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.camera_alt_outlined, color: primaryBlue, size: 20),
              ),
              SizedBox(width: 12),
              Text('Scan Data Barang', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: darkBlue)),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Gunakan kamera untuk mengisi form secara otomatis dari label barang.',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          _isProcessingOcr
              ? Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
            icon: Icon(Icons.camera_enhance_rounded),
            label: Text('Buka Kamera & Scan'),
            onPressed: () => _pickAndProcessImage(ImageSource.camera),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    if (_currentFormConfigs.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat formulir...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_currentFormConfigs.first.fieldName == 'error') {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                _currentFormConfigs.first.labelDisplay,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: surfaceBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_note,
                  color: primaryBlue,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Informasi Barang',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          ..._currentFormConfigs
              .where((config) => config.fieldName != 'tipe_barang')
              .map((config) => _buildInputField(config))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: primaryBlue.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Simpan Data',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                // Clear all fields
                _controllers.forEach((key, controller) => controller.clear());
                _selectedDropdownValues.clear();
                setState(() {});
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: BorderSide(color: primaryBlue, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.clear, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Reset Form',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        title: Text(
          'Input Barang Masuk',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildCategoryCard(),
            if (_selectedType == 'APAR')
              _buildOcrCard(),
            _buildFormCard(),
            SizedBox(height: 24),
            _buildActionButtons(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}