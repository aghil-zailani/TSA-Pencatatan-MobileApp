import 'dart:convert';
import 'package:http/http.dart' as http;

class api_service {
  static const String _baseUrl = 'http://10.0.2.2:8000/api'; //  Ganti dengan URL API Anda (10.0.2.2 untuk emulator Android)

  Future<List<Barang>> fetchBarang() async {
    final response = await http.get(Uri.parse('$_baseUrl/barangs'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Barang.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch barang');
    }
  }

// ... (fungsi lain untuk createBarang, updateBarang, deleteBarang)
}

class Barang {
  final int id;
  final String namaBarang;
  final String tipeBarang;
  final int jumlah;

  Barang({required this.id, required this.namaBarang, required this.tipeBarang, required this.jumlah});

  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(
      id: json['id'],
      namaBarang: json['nama_barang'],
      tipeBarang: json['tipe_barang'],
      jumlah: json['jumlah'],
    );
  }
}