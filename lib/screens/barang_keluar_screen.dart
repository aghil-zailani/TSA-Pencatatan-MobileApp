import 'package:flutter/material.dart';

class BarangKeluarScreen extends StatefulWidget {
  @override
  _BarangKeluarScreenState createState() => _BarangKeluarScreenState();
}

class _BarangKeluarScreenState extends State<BarangKeluarScreen> {
  final List<TextEditingController> _idBarangControllers = [TextEditingController()];
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _tujuanController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  final Color primaryBlue = Color(0xFF2196F3);
  final Color lightBlue = Color(0xFF42A5F5);
  final Color darkBlue = Color(0xFF0D47A1);
  final Color backgroundBlue = Color(0xFFF3F8FF);
  final Color surfaceBlue = Color(0xFFE3F2FD);

  @override
  void dispose() {
    for (var c in _idBarangControllers) {
      c.dispose();
    }
    _namaBarangController.dispose();
    _tujuanController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _addIdBarangField() {
    setState(() {
      _idBarangControllers.add(TextEditingController());
    });
  }

  void _removeIdBarangField(int index) {
    if (_idBarangControllers.length > 1) {
      setState(() {
        _idBarangControllers[index].dispose();
        _idBarangControllers.removeAt(index);
      });
    }
  }

  void _showDuplicateDialog(String duplicateId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Peringatan!'),
        content: Text('ID Barang "$duplicateId" sudah ada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _saveData() {
    final enteredIds = _idBarangControllers.map((c) => c.text.trim()).where((id) => id.isNotEmpty).toList();

    final duplicate = _findDuplicateId(enteredIds);
    if (duplicate != null) {
      _showDuplicateDialog(duplicate);
      return;
    }

    final namaBarang = _namaBarangController.text.trim();
    final tujuan = _tujuanController.text.trim();
    final keterangan = _keteranganController.text.trim();

    if (enteredIds.isEmpty || namaBarang.isEmpty || tujuan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semua data wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Kirim ke backend dengan http.post
    debugPrint('Data disimpan:');
    debugPrint('ID Barang: $enteredIds');
    debugPrint('Nama: $namaBarang, Tujuan: $tujuan, Keterangan: $keterangan');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data berhasil disimpan!')),
    );
  }

  String? _findDuplicateId(List<String> ids) {
    final seen = <String>{};
    for (var id in ids) {
      if (seen.contains(id)) return id;
      seen.add(id);
    }
    return null;
  }

  void _resetForm() {
    for (var c in _idBarangControllers) {
      c.clear();
    }
    _namaBarangController.clear();
    _tujuanController.clear();
    _keteranganController.clear();
    setState(() {});
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
              Icons.outbox_outlined,
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
                  'Pencatatan Barang Keluar',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola barang yang keluar dari gudang',
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

  Widget _buildIdBarangFields() {
    return Column(
      children: List.generate(_idBarangControllers.length, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idBarangControllers[i],
                  decoration: InputDecoration(
                    labelText: 'ID Barang',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: primaryBlue),
                onPressed: _addIdBarangField,
              ),
              if (i > 0)
                IconButton(
                  icon: Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _removeIdBarangField(i),
                ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        title: Text(
          'Barang Keluar',
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
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Text('ID Barang', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  _buildIdBarangFields(),
                  SizedBox(height: 16),
                  TextField(
                    controller: _namaBarangController,
                    decoration: InputDecoration(
                      labelText: 'Nama Barang',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _tujuanController,
                    decoration: InputDecoration(
                      labelText: 'Tujuan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _keteranganController,
                    decoration: InputDecoration(
                      labelText: 'Keterangan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _saveData,
              icon: Icon(Icons.save, size: 20),
              label: Text(
                'Simpan Data',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),

            SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _resetForm,
              icon: Icon(Icons.close, size: 20),
              label: Text(
                'Reset Form',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: primaryBlue,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryBlue, width: 2),
                foregroundColor: primaryBlue,
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
