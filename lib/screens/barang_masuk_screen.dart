import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    _fetchAvailableCategories().then((_) {
      _fetchFormData(_selectedType);
    });
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchAvailableCategories() async {
    const String baseUrl = 'http://192.168.56.96:8000/api';
    try {
      final response = await http.get(Uri.parse('$baseUrl/master-data/category_name'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> categories = data['categories'];
        setState(() {
          _availableCategories = categories.cast<String>();
          if (!_availableCategories.contains(_selectedType)) {
            _selectedType = _availableCategories.first;
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
    return fieldName == 'tipe_barang' || fieldName == 'satuan';
  }

  List<String> _getManualDropdownOptions(String fieldName) {
    if (fieldName == 'tipe_barang') {
      if (_selectedType == 'APAR') {
        return ['ABC Powder', 'Foam', 'CO2'];
      } else if (_selectedType == 'Hydrant') {
        return ['Pilar', 'Hydrant Box'];
      }
    } else if (fieldName == 'satuan') {
      return ['Kg', 'Pcs', 'Meter', 'Liter'];
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

  void _saveData() {
    Map<String, dynamic> dataToSave = {
      'tipe_barang_kategori': _selectedType,
    };

    for (var config in _currentFormConfigs) {
      dynamic value;
      if (config.inputType == 'dropdown' || _isManualDropdown(config.fieldName)) {
        value = _selectedDropdownValues[config.fieldName];
      } else {
        value = _controllers[config.fieldName]?.text;
      }

      if (config.isRequired && (value == null || value.toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${config.labelDisplay} wajib diisi!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }
      dataToSave[config.fieldName] = value;
    }

    print('Data yang akan disimpan: $dataToSave');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data berhasil disimpan!'),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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
          ..._currentFormConfigs.map((config) => _buildInputField(config)).toList(),
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