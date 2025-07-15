import 'package:flutter/material.dart';
import '../widgets/input_field.dart';
import '../widgets/custom_button.dart';

class APARSpartScreen extends StatefulWidget {
  @override
  _APARSpartScreenState createState() => _APARSpartScreenState();
}

class _APARSpartScreenState extends State<APARSpartScreen> {
  final _namaBarangController = TextEditingController();
  final _beratController = TextEditingController();
  final _merekBarangController = TextEditingController();
  final _sizeController = TextEditingController();
  final _satuanController = TextEditingController();
  final _kondisiBarangController = TextEditingController();
  final _jumlahBarangController = TextEditingController();

  // Enhanced Blue Color Palette
  final Color primaryBlue = Color(0xFF1976D2);
  final Color lightBlue = Color(0xFF42A5F5);
  final Color darkBlue = Color(0xFF0D47A1);
  final Color accentBlue = Color(0xFF03DAC6);
  final Color backgroundBlue = Color(0xFFF3F8FF);
  final Color surfaceBlue = Color(0xFFE3F2FD);

  @override
  void dispose() {
    _namaBarangController.dispose();
    _beratController.dispose();
    _merekBarangController.dispose();
    _sizeController.dispose();
    _satuanController.dispose();
    _kondisiBarangController.dispose();
    _jumlahBarangController.dispose();
    super.dispose();
  }

  Widget _buildInputField({
    required String labelText,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: darkBlue,
        ),
        decoration: InputDecoration(
          labelText: labelText,
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
              icon,
              color: primaryBlue,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
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
              Icons.fire_extinguisher,
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
                  'APAR Sparepart',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola data suku cadang APAR',
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

  Widget _buildFormCard() {
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
          _buildInputField(
            labelText: 'Nama Barang',
            controller: _namaBarangController,
            icon: Icons.inventory_2_outlined,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  labelText: 'Berat',
                  controller: _beratController,
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  labelText: 'Size',
                  controller: _sizeController,
                  icon: Icons.format_size,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInputField(
            labelText: 'Merek Barang',
            controller: _merekBarangController,
            icon: Icons.branding_watermark,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  labelText: 'Satuan',
                  controller: _satuanController,
                  icon: Icons.straighten,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  labelText: 'Jumlah',
                  controller: _jumlahBarangController,
                  icon: Icons.numbers,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInputField(
            labelText: 'Kondisi Barang',
            controller: _kondisiBarangController,
            icon: Icons.check_circle_outline,
          ),
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
              onPressed: () {
                final namaBarang = _namaBarangController.text;
                final berat = _beratController.text;
                final merekBarang = _merekBarangController.text;
                final size = _sizeController.text;
                final satuan = _satuanController.text;
                final kondisiBarang = _kondisiBarangController.text;
                final jumlahBarang = _jumlahBarangController.text;

                print(
                  'Nama Barang: $namaBarang, Berat: $berat, Merek: $merekBarang, Size: $size, Satuan: $satuan, Kondisi: $kondisiBarang, Jumlah: $jumlahBarang',
                );

                // Show success message
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
              },
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
                _namaBarangController.clear();
                _beratController.clear();
                _merekBarangController.clear();
                _sizeController.clear();
                _satuanController.clear();
                _kondisiBarangController.clear();
                _jumlahBarangController.clear();
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
          'APAR Sparepart',
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