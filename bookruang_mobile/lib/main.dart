import 'package:flutter/material.dart';

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

  List<Map<String, dynamic>> daftarPeminjaman = [];

  int? editIndex;

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
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  if(editIndex != null){
                                    //Mode edit
                                    daftarPeminjaman[editIndex!] = {
                                      "nama" : namaController.text,
                                      "ruangan" : ruanganController.text,
                                      "tanggal" : DateTime.now(),
                                    };
                                    editIndex = null;
                                  }else {
                                    // Mode tambah
                                    daftarPeminjaman.add({
                                      "nama" : namaController.text,
                                      "ruangan" : ruanganController.text,
                                      "tanggal" : DateTime.now(),
                                    });
                                  }
                                });

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
                            "${item["nama"]} - ${item["ruangan"]}"),
                        subtitle: Text(
                            "${item["tanggal"].toString().split(' ')[0]}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                setState(() {
                                  namaController.text = item["nama"];
                                  ruanganController.text = item["ruangan"];
                                  editIndex = index;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  daftarPeminjaman.removeAt(index);
                                });
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
