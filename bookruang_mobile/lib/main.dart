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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
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
  final TextEditingController tujuanController = TextEditingController();
  final String apiUrl = "http://127.0.0.1:5021/api/RoomLoans"; // Android emulator
  // Untuk device fisik, ganti dengan IP komputer Anda: http://192.168.x.x:5021/api/RoomLoans

  List<Map<String, dynamic>> daftarPeminjaman = [];
  List<Map<String, dynamic>> filteredPeminjaman = [];
  Map<String, int>? statistics;
  
  int? editIndex;
  bool isLoading = false;
  String selectedStatus = 'Semua';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchStatistics();
  }

  @override
  void dispose() {
    namaController.dispose();
    ruanganController.dispose();
    tujuanController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      setState(() => isLoading = true);
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          daftarPeminjaman = List<Map<String, dynamic>>.from(data);
          applyFilters();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() => isLoading = false);
      showSnackBar('Gagal memuat data: $e', isError: true);
    }
  }

  Future<void> fetchStatistics() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/statistics'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          statistics = {
            'total': data['total'],
            'pending': data['pending'],
            'approved': data['approved'],
            'rejected': data['rejected'],
          };
        });
      }
    } catch (e) {
      print('Failed to load statistics: $e');
    }
  }

  void applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(daftarPeminjaman);

    // Filter by status
    if (selectedStatus != 'Semua') {
      filtered = filtered.where((loan) {
        return loan['status'].toString().toLowerCase() == 
               selectedStatus.toLowerCase();
      }).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((loan) {
        final borrowerName = loan['borrowerName'].toString().toLowerCase();
        final roomName = loan['roomName'].toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        return borrowerName.contains(query) || roomName.contains(query);
      }).toList();
    }

    setState(() {
      filteredPeminjaman = filtered;
    });
  }

  Future<void> tambahData() async {
    try {
      setState(() => isLoading = true);
      final now = DateTime.now();
      await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "borrowerName": namaController.text,
          "roomName": ruanganController.text,
          "purpose": tujuanController.text,
          "date": now.toIso8601String(),
          "startTime": now.toIso8601String(),
          "endTime": now.add(const Duration(hours: 2)).toIso8601String(),
          "status": "Pending"
        }),
      );

      await fetchData();
      await fetchStatistics();
      showSnackBar('Peminjaman berhasil ditambahkan!');
    } catch (e) {
      showSnackBar('Gagal menambah data: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> editData(int id) async {
    try {
      setState(() => isLoading = true);
      await http.put(
        Uri.parse("$apiUrl/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id,
          "borrowerName": namaController.text,
          "roomName": ruanganController.text,
          "purpose": tujuanController.text,
          "date": DateTime.now().toIso8601String(),
          "status": "Pending",
        }),
      );

      await fetchData();
      await fetchStatistics();
      showSnackBar('Peminjaman berhasil diperbarui!');
    } catch (e) {
      showSnackBar('Gagal memperbarui data: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> hapusData(int id) async {
    try {
      await http.delete(Uri.parse("$apiUrl/$id"));
      await fetchData();
      await fetchStatistics();
      showSnackBar('Peminjaman berhasil dihapus!');
    } catch (e) {
      showSnackBar('Gagal menghapus data: $e', isError: true);
    }
  }

  Future<void> approveData(int id, String adminName, String? notes) async {
    try {
      setState(() => isLoading = true);
      await http.put(
        Uri.parse("$apiUrl/$id/approve"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "updatedBy": adminName,
          "notes": notes ?? "",
        }),
      );

      await fetchData();
      await fetchStatistics();
      showSnackBar('Peminjaman berhasil disetujui!');
    } catch (e) {
      showSnackBar('Gagal approve: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> rejectData(int id, String adminName, String notes) async {
    try {
      setState(() => isLoading = true);
      await http.put(
        Uri.parse("$apiUrl/$id/reject"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "updatedBy": adminName,
          "notes": notes,
        }),
      );

      await fetchData();
      await fetchStatistics();
      showSnackBar('Peminjaman berhasil ditolak!');
    } catch (e) {
      showSnackBar('Gagal reject: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void showApproveDialog(Map<String, dynamic> loan) {
    final TextEditingController adminController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('✓ Setujui Peminjaman'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Peminjam: ${loan['borrowerName']}'),
                  Text('Ruangan: ${loan['roomName']}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: adminController,
              decoration: const InputDecoration(
                labelText: 'Nama Admin *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (adminController.text.isEmpty) {
                showSnackBar('Nama admin wajib diisi!', isError: true);
                return;
              }
              Navigator.pop(context);
              approveData(
                loan['id'],
                adminController.text,
                notesController.text.isEmpty ? null : notesController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  void showRejectDialog(Map<String, dynamic> loan) {
    final TextEditingController adminController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('✗ Tolak Peminjaman'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Peminjam: ${loan['borrowerName']}'),
                  Text('Ruangan: ${loan['roomName']}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: adminController,
              decoration: const InputDecoration(
                labelText: 'Nama Admin *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Alasan Penolakan *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (adminController.text.isEmpty || notesController.text.isEmpty) {
                showSnackBar('Nama admin dan alasan wajib diisi!', isError: true);
                return;
              }
              Navigator.pop(context);
              rejectData(loan['id'], adminController.text, notesController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  void showDetailDialog(Map<String, dynamic> loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('📋 Detail Peminjaman'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Peminjam', loan['borrowerName']),
              _buildDetailRow('Ruangan', loan['roomName']),
              _buildDetailRow('Tujuan', loan['purpose']),
              _buildDetailRow('Status', loan['status']),
              const Divider(height: 24),
              if (loan['approvedBy'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✓ Disetujui',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Oleh: ${loan['approvedBy']}'),
                      if (loan['notes'] != null)
                        Text('Catatan: ${loan['notes']}'),
                    ],
                  ),
                ),
              ],
              if (loan['rejectedBy'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✗ Ditolak',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Oleh: ${loan['rejectedBy']}'),
                      if (loan['notes'] != null)
                        Text('Alasan: ${loan['notes']}'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1).withOpacity(0.1),
              const Color(0xFF8B5CF6).withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.meeting_room_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "BookRuang",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Sistem Peminjaman Ruangan",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (statistics != null) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total',
                              statistics!['total'].toString(),
                              Icons.list_alt,
                              Colors.white.withOpacity(0.2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Pending',
                              statistics!['pending'].toString(),
                              Icons.pending,
                              Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Approved',
                              statistics!['approved'].toString(),
                              Icons.check_circle,
                              Colors.green.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Filter & Search
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedStatus,
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                items: ['Semua', 'Pending', 'Approved', 'Rejected']
                                    .map((status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(status),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedStatus = value!;
                                    applyFilters();
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Cari...',
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                  applyFilters();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPeminjaman.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Belum ada peminjaman",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchData,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredPeminjaman.length,
                              itemBuilder: (context, index) {
                                final item = filteredPeminjaman[index];
                                final isPending = item['status'] == 'Pending';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF6366F1),
                                            Color(0xFF8B5CF6),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.meeting_room,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      item["borrowerName"],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.room, size: 14),
                                            const SizedBox(width: 4),
                                            Text(item["roomName"]),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: getStatusColor(item['status'])
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item['status'],
                                            style: TextStyle(
                                              color: getStatusColor(item['status']),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'detail',
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline, size: 20),
                                              SizedBox(width: 8),
                                              Text('Detail'),
                                            ],
                                          ),
                                        ),
                                        if (isPending) ...[
                                          const PopupMenuItem(
                                            value: 'approve',
                                            child: Row(
                                              children: [
                                                Icon(Icons.check, color: Colors.green, size: 20),
                                                SizedBox(width: 8),
                                                Text('Approve'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'reject',
                                            child: Row(
                                              children: [
                                                Icon(Icons.close, color: Colors.red, size: 20),
                                                SizedBox(width: 8),
                                                Text('Reject'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 20),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red, size: 20),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'detail':
                                            showDetailDialog(item);
                                            break;
                                          case 'approve':
                                            showApproveDialog(item);
                                            break;
                                          case 'reject':
                                            showRejectDialog(item);
                                            break;
                                          case 'edit':
                                            setState(() {
                                              namaController.text = item["borrowerName"];
                                              ruanganController.text = item["roomName"];
                                              tujuanController.text = item["purpose"];
                                              editIndex = index;
                                            });
                                            break;
                                          case 'delete':
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Hapus Peminjaman'),
                                                content: const Text(
                                                  'Apakah Anda yakin ingin menghapus peminjaman ini?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Batal'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      hapusData(item["id"]);
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                    ),
                                                    child: const Text('Hapus'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            break;
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(editIndex != null ? 'Edit Peminjaman' : 'Tambah Peminjaman'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: "Nama Peminjam",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
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
                        prefixIcon: Icon(Icons.room),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Nama ruangan tidak boleh kosong";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: tujuanController,
                      decoration: const InputDecoration(
                        labelText: "Tujuan",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Tujuan tidak boleh kosong";
                        }
                        return null;
                      },
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    namaController.clear();
                    ruanganController.clear();
                    tujuanController.clear();
                    setState(() => editIndex = null);
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      if (editIndex != null) {
                        int id = daftarPeminjaman[editIndex!]["id"];
                        await editData(id);
                        editIndex = null;
                      } else {
                        await tambahData();
                      }

                      namaController.clear();
                      ruanganController.clear();
                      tujuanController.clear();
                    }
                  },
                  child: Text(editIndex != null ? 'Perbarui' : 'Simpan'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}