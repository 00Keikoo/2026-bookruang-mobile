import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const BookRuangApp());
}

class BookRuangApp extends StatelessWidget {
  const BookRuangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookRuang',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BookRuangPage(),
    );
  }
}

class BookRuangPage extends StatefulWidget {
  const BookRuangPage({super.key});

  @override
  State<BookRuangPage> createState() => _BookRuangPageState();
}

class _BookRuangPageState extends State<BookRuangPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController ruanganController = TextEditingController();
  final String apiUrl = "http://127.0.0.1:5021/api/RoomLoans";

  List<Map<String, dynamic>> daftarPeminjaman = [];

  int? editIndex;

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(apiUrl));

    if(response.statusCode == 200){
      final List data = jsonDecode(response.body);
      setState(() {
        daftarPeminjaman = List<Map<String, dynamic>>.from(data);
      });
    } else {
      print("Gagal ambil data");
    }
  }

  @override
  void initState(){
    super.initState();
    fetchData();
  }

  // Fungsi tambahData
  Future<void> tambahData() async{
    await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "borrowerName": namaController.text,
        "roomName": ruanganController.text,
        "purpose": "Mobile App",
        "date": DateTime.now().toIso8601String(),
        "status": "pending"
      }),
    );

    fetchData();
  }

  // Fungsi editData
  Future<void> editData(int id) async {
    await http.put(
      Uri.parse("$apiUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "borrowerName": namaController.text,
        "roomName": ruanganController.text, 
        "purpose": "Mobile App",
        "date": DateTime.now().toIso8601String(),
        "status": "pending",
      }),
    );

    fetchData();
  }

  // Fungsi hapusData
  Future<void> hapusData(int id) async {
    await http.delete(Uri.parse("$apiUrl/$id"));
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BookRuang"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          "Tambah Peminjaman",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: namaController,
                          decoration: const InputDecoration(
                            labelText: "Nama Peminjam",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Nama peminjam tidak boleh kosong";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: ruanganController,
                          decoration: const InputDecoration(
                            labelText: "Nama Ruangan",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Nama ruangan tidak boleh kosong";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async{
                              if(_formKey.currentState!.validate()){
                                if(editIndex != null){
                                  int id = daftarPeminjaman[editIndex!]["id"];
                                  await editData(id);
                                  editIndex = null;
                                }else{
                                  await tambahData();
                                }

                                namaController.clear();
                                ruanganController.clear();
                              }
                            },
                            child: const Text("Simpan"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Daftar Peminjaman",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: ListView.builder(
                  itemCount: daftarPeminjaman.length,
                  itemBuilder: (context, index) {
                    final item = daftarPeminjaman[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                            "${item["borrowerName"]} - ${item["roomName"]}"),
                        subtitle: Text(
                            "${item["date"].toString().split('T')[0]}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async{
                                setState(() {
                                  namaController.text = item["borrowerName"];
                                  ruanganController.text = item["roomName"];
                                  editIndex = index;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async{
                                hapusData(item["id"]);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
