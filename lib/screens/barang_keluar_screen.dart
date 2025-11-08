import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarangKeluarScreen extends StatefulWidget {
  @override
  _BarangKeluarScreenState createState() => _BarangKeluarScreenState();
}

class QRScannerScreen extends StatefulWidget {
  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        backgroundColor: Colors.blue,
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (!_isScanning) return;
          final barcode = capture.barcodes.first;
          if (barcode.rawValue == null) return;

          final String raw = barcode.rawValue!;
          debugPrint('Hasil QR: $raw');

          final parts = raw.split(':');
          String idOnly = raw;
          if (parts.length >= 2) {
            final afterColon = parts[1].trim();
            idOnly = afterColon.split(RegExp(r'\s+')).first.trim();
          }

          setState(() {
            _isScanning = false;
          });

          controller.stop();
          Navigator.of(context).pop(idOnly);
        },
      ),
    );
  }
}

class _BarangKeluarScreenState extends State<BarangKeluarScreen> {
  final List<TextEditingController> _idBarangControllers = [TextEditingController()];
  final List<TextEditingController> _jumlahBarangControllers = [TextEditingController()];
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
    _tujuanController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _addIdBarangField() {
    setState(() {
      _idBarangControllers.add(TextEditingController());
      _jumlahBarangControllers.add(TextEditingController());
    });
  }

  void _removeIdBarangField(int index) {
    if (_idBarangControllers.length > 1) {
      setState(() {
        _idBarangControllers[index].dispose();
        _jumlahBarangControllers[index].dispose();
        _idBarangControllers.removeAt(index);
        _jumlahBarangControllers.removeAt(index);
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

  void _saveData() async {
    final enteredIds = _idBarangControllers.map((c) => c.text.trim()).where((id) => id.isNotEmpty).toList();
    final enteredJumlah = _jumlahBarangControllers.map((c) => c.text.trim()).toList();

    final duplicate = _findDuplicateId(enteredIds);
    if (duplicate != null) {
      _showDuplicateDialog(duplicate);
      return;
    }

    final tujuan = _tujuanController.text.trim();
    final keterangan = _keteranganController.text.trim();

    if (enteredIds.isEmpty || tujuan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua data wajib diisi!')),
      );
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < enteredIds.length; i++) {
      final jumlah = int.tryParse(enteredJumlah[i]) ?? 0;
      if (jumlah <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jumlah barang harus lebih dari 0')),
        );
        return;
      }
      items.add({
        'id_barang': enteredIds[i],
        'jumlah_barang': jumlah,
      });
    }

    final payload = {
      'items': items,
      'tujuan': tujuan,
      'keterangan': keterangan,
    };

    debugPrint('Payload: $payload');

    try {
      final response = await http.post(
        // Uri.parse('http://192.168.56.96:8000/api/transaksi/barang-keluar'), // GANTI SESUAI ENDPOINT
        Uri.parse('http://192.168.100.137:8000/api/transaksi/barang-keluar'), // GANTI SESUAI ENDPOINT
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Barang keluar berhasil dicatat!')),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${response.body}')),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan koneksi.')),
      );
    }
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
    for (var c in _jumlahBarangControllers) {
      c.clear();
    }
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

  Future<void> _scanQrForIndex(int index) async {
    final scanned = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => QRScannerScreen(),
      ),
    );

    if (scanned != null && scanned is String) {
      // Pisahkan ID dari teks, misal formatnya selalu: "Data Barang ID : <ID>"
      final parts = scanned.split(':');
      String idOnly = scanned; // fallback kalau parsing gagal

      if (parts.length >= 2) {
        idOnly = parts[1].trim(); // Ambil bagian setelah ':' dan hapus spasi
      }

      setState(() {
        _idBarangControllers[index].text = idOnly;
      });
    }
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
                  decoration: InputDecoration(labelText: 'ID Barang'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _jumlahBarangControllers[i],
                  decoration: InputDecoration(labelText: 'Jumlah'),
                  keyboardType: TextInputType.number,
                ),
              ),
              IconButton(
              icon: Icon(Icons.qr_code_scanner),
              onPressed: () => _scanQrForIndex(i),
              ),
              IconButton(
                icon: Icon(Icons.add_circle),
                onPressed: _addIdBarangField,
              ),
              if (i > 0)
                IconButton(
                  icon: Icon(Icons.remove_circle),
                  onPressed: () => _removeIdBarangField(i),
                ),
            ],
          )
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
