import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alza-Laundry',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TestAPI(),
    );
  }
}

class TestAPI extends StatefulWidget {
  const TestAPI({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TestAPIState createState() => _TestAPIState();
}

class _TestAPIState extends State<TestAPI> {
  final _formKey = GlobalKey<FormState>();
  final _idInvoiceController = TextEditingController();
  // ignore: prefer_typing_uninitialized_variables
  var _error;
  // ignore: prefer_typing_uninitialized_variables
  var _invoice;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final idInvoice = _idInvoiceController.text;

    try {
      final response = await http.post(
        Uri.parse('https://afvr.my.id/api/cek_status'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'id_invoice': idInvoice},
      );

      final responseData = json.decode(response.body);

      if (responseData['error'] != null) {
        setState(() {
          _error = responseData['error'];
          _invoice = null;
        });
      } else {
        setState(() {
          _error = null;
          _invoice = responseData['id_invoice'];
        });
      }
    } catch (error) {
      setState(() {
        _error = 'Terjadi kesalahan saat menghubungi server, pastikan perangkat Anda terhubung ke internet.';
        _invoice = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Status Laundry'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _idInvoiceController,
                  decoration: const InputDecoration(labelText: 'ID Invoice'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'ID Invoice harus diisi, pastikan Anda menulisnya dengan benar.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Cek Status'),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(
                    _error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (_invoice != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16.0,
                        columns: const [
                          DataColumn(label: Text('ID Invoice')),
                          DataColumn(label: Text('Tanggal')),
                          DataColumn(label: Text('Nama Pelanggan')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: _invoice.map<DataRow>((invoice) {
                          return DataRow(cells: [
                            DataCell(Text(invoice['id_invoice'].toString())),
                            DataCell(Text(invoice['transaksi_tanggal'])),
                            DataCell(Text(invoice['nama_konsumen'])),
                            DataCell(
                              Container(
                                width: 180,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      invoice['status_transaksi'] == 'Selesai'
                                          ? Colors.green
                                          : Colors.red,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  invoice['status_transaksi'] == 'Selesai'
                                      ? 'Cucian Sudah Bisa Diambil'
                                      : 'Cucian Sedang Diproses',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder(
                      future: Future.delayed(Duration.zero),
                      builder:
                          (BuildContext context, AsyncSnapshot<void> snapshot) {
                        return Column(
                          children: _invoice.map<Widget>((invoice) {
                            if (invoice['status_transaksi'] == 'Selesai') {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            const Text(
                                              'Cucian Sudah Bisa Diambil',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Silakan datang ke outlet untuk mengambil cucian Anda.',
                                              style: TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: <Widget>[
                                                TextButton(
                                                  child: const Text('OK'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              });
                            }
                            return Container();
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
