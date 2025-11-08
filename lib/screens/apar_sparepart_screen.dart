import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// UTILITY CLASS: Untuk menampung konfigurasi setiap field dari API
// Menggunakan 'value' dari master_data sebagai fieldName
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

  // Fungsi untuk mendapatkan ikon berdasarkan nama field
  IconData getIconData() {
    switch (fieldName) {
      case 'nama_barang': return Icons.label_outline;
      case 'tipe_barang': return Icons.category_outlined;
      case 'jumlah_barang': return Icons.numbers_outlined;
      case 'satuan': return Icons.straighten_outlined;
      case 'kondisi': return Icons.health_and_safety_outlined;
      case 'berat': return Icons.scale_outlined;
      case 'tanggal_kadaluarsa': return Icons.calendar_today_outlined;
      case 'ukuran_barang': return Icons.square_foot_outlined;
      case 'panjang': return Icons.straighten;
      case 'lebar': return Icons.width_wide_outlined;
      case 'tinggi': return Icons.height_outlined;
      case 'merek': return Icons.branding_watermark_outlined;
      default: return Icons.help_outline;
    }
  }
}

// SCREEN: Halaman yang difokuskan untuk kategori "Sparepart"
class SparepartScreen extends StatefulWidget {
  const SparepartScreen({Key? key}) : super(key: key);

  @override
  _SparepartScreenState createState() => _SparepartScreenState();
}

class _SparepartScreenState extends State<SparepartScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectedDropdownValues = {};
  List<FormFieldConfig> _currentFormConfigs = [];
  String _selectedType = 'Sparepart';
  bool _isLoading = true;
  String? _errorMessage;

  // Palet Warna
  final Color primaryBlue = Color(0xFF1976D2);
  final Color lightBlue = Color(0xFF42A5F5);
  final Color darkBlue = Color(0xFF0D47A1);
  final Color backgroundBlue = Color(0xFFF3F8FF);
  final Color surfaceBlue = Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    // Langsung memuat form untuk kategori "Sparepart"
    _fetchFormData('Sparepart');
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // Mengambil konfigurasi form dari API
  Future<void> _fetchFormData(String formType) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentFormConfigs = [];
      _selectedDropdownValues.clear();
      _controllers.forEach((key, controller) => controller.dispose());
      _controllers.clear();
    });

    const String baseUrl = 'http://192.168.100.137:8000/api'; // Ganti IP sesuai jaringanmu
    try {
      final configResponse = await http.get(Uri.parse('$baseUrl/form-configs/$formType'));

      if (configResponse.statusCode == 200) {
        List<dynamic> configData = json.decode(configResponse.body);
        List<FormFieldConfig> fetchedConfigs = configData.map((json) => FormFieldConfig.fromJson(json)).toList();
        fetchedConfigs.sort((a, b) => a.fieldOrder.compareTo(b.fieldOrder));

        setState(() {
          _currentFormConfigs = fetchedConfigs;

          // ✅ FIX: Manual dropdown juga diinisialisasi
          for (var config in _currentFormConfigs) {
            if (config.inputType == 'dropdown' || _isManualDropdown(config.fieldName)) {
              _selectedDropdownValues[config.fieldName] = null;
            } else {
              _controllers[config.fieldName] = TextEditingController();
            }
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal Memuat Form (Status ${configResponse.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal Memuat Form: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Mengambil opsi untuk dropdown dari API
  Future<List<String>> _fetchDropdownOptions(String fieldName) async {
    const String baseUrl = 'http://192.168.100.137:8000/api';
    try {
      final response = await http.get(Uri.parse('$baseUrl/master-data/$fieldName'));
      if (response.statusCode == 200) {
        final List<dynamic> options = json.decode(response.body);
        return options.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Menyimpan data ke backend
  void _saveData() async {
    final _storage = FlutterSecureStorage();

    // 3. Ambil token dari storage
    final String? token = await _storage.read(key: 'api_token');

    // 4. Validasi token untuk memastikan user sudah login
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Map<String, dynamic> dataToSave = {
      'tipe_barang_kategori': 'Sparepart', // Kategori sudah pasti "Sparepart"
    };

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

      if (config.isRequired && (value == null || value.toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${config.labelDisplay} wajib diisi!'), backgroundColor: Colors.red),
        );
        return;
      }
      dataToSave[config.fieldName] = value;
    }

    if (_selectedType == 'Sparepart') {
      dataToSave['tipe_barang'] = 'Sparepart';
    }

    const String baseUrl = 'http://192.168.100.137:8000/api';

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json', // <-- Penting agar Laravel membalas dengan JSON
      'Authorization': 'Bearer $token', // <-- Penting untuk otentikasi
    };

    // 6. Gunakan headers yang sudah dibuat saat melakukan request
    final postResponse = await http.post(
      Uri.parse('$baseUrl/pengajuan-barangs'),
      headers: headers, // <-- Gunakan headers di sini
      body: json.encode(dataToSave),
    );

    if (postResponse.statusCode == 201 || postResponse.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data berhasil disimpan!'), backgroundColor: Colors.green),
      );
      _controllers.forEach((_, controller) => controller.clear());
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

  // Memilih tanggal
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

  // Widget Header
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

  bool _isManualDropdown(String fieldName) {
    return fieldName == 'satuan' || fieldName == 'kondisi';
  }

  List<String> _getManualDropdownOptions(String fieldName) {
    if (fieldName == 'satuan') {
      return ['Kg', 'Pcs', 'Meter', 'Liter'];
    } else if (fieldName == 'kondisi'){
      return ['Bagus', 'Rusak', 'Expired'];
    }
    return [];
  }

  // Widget untuk membangun input field
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
            return // ✅ FIXED: Dropdown benar
              DropdownButtonFormField<String>(
                value: _selectedDropdownValues[config.fieldName] ?? null,
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
                onChanged: (newValue) {
                  setState(() {
                    _selectedDropdownValues[config.fieldName] = newValue ?? '';
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

  // Widget untuk container form
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

  // Widget untuk tombol aksi
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
          'Input Sparepart', // Judul AppBar diubah
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white),
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
            // PERBAIKAN: _buildCategoryCard() dihapus karena tidak diperlukan lagi
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
