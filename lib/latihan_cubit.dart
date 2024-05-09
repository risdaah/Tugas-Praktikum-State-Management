import 'package:flutter/material.dart';
// Import untuk HTTP requests
import 'package:http/http.dart' as http;
// Import untuk JSON parsing
import 'dart:convert';
// Import untuk membuka URL di browser eksternal
import 'package:url_launcher/url_launcher.dart';
// Import untuk Flutter BLoC
import 'package:flutter_bloc/flutter_bloc.dart';

// Model untuk data universitas
class Univ {
  String name; // Nama universitas
  String website; // Website universitas

  // Constructor Univ
  Univ({required this.name, required this.website});
}

// Class untuk manajemen state universitas menggunakan Cubit
class UniversityCubit extends Cubit<List<Univ>> {
  UniversityCubit()
      : super([]); // Constructor untuk inisialisasi dengan list kosong

  String baseUrl =
      "http://universities.hipolabs.com/search?country="; // Base URL untuk request
  String selectedCountry =
      "Indonesia"; // Negara yang dipilih, default Indonesia

  // Method untuk mengambil data universitas dari server
  Future<void> fetchData(String country) async {
    final response = await http
        .get(Uri.parse(baseUrl + country)); // Mengirim HTTP GET request

    // Memeriksa status code response
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body); // Parsing JSON response
      List<Univ> universities = [];

      // Looping melalui data JSON dan membuat objek Univ untuk setiap item
      for (var item in data) {
        universities.add(Univ(
          name: item['name'],
          website: item['web_pages'][0],
        ));
      }

      emit(universities);
      // Menampilkan data universitas ke UI
    } else {
      emit('Gagal' as List<Univ>);
      // Jika request gagal, memancarkan pesan 'Gagal' ke UI
    }
  }

  // Method untuk memperbarui negara yang dipilih
  void updateCountry(String newCountry) {
    selectedCountry = newCountry;
    fetchData(selectedCountry);
    // Memperbarui data universitas berdasarkan negara yang dipilih
  }
}

// Fungsi main
void main() {
  runApp(
    BlocProvider(
      create: (context) => UniversityCubit()..fetchData("Indonesia"),
      // Membuat instance UniversityCubit dan memuat data untuk negara default Indonesia
      child: const MyApp(), // Menjalankan aplikasi
    ),
  );
}

// Class utama aplikasi Flutter
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daftar Universitas',
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Daftar Universitas',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: context
                      .watch<UniversityCubit>()
                      // Mendapatkan nilai negara yang dipilih dari UniversityCubit
                      .selectedCountry,
                  items: <String>[
                    'Indonesia',
                    'Singapore',
                    'Malaysia',
                    'Thailand',
                    'Philippines',
                    'Viet Nam',
                    "Lao People's Democratic Republic",
                    'Cambodia',
                    'Myanmar',
                    'Brunei Darussalam'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      context.read<UniversityCubit>().updateCountry(newValue);
                      // Memperbarui negara yang dipilih ketika dropdown berubah
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: BlocBuilder<UniversityCubit, List<Univ>>(
            builder: (context, universityList) {
              if (universityList.isNotEmpty) {
                // Jika daftar universitas tidak kosong
                return ListView.builder(
                  itemCount: universityList.length,
                  itemBuilder: (context, index) {
                    final univ = universityList[index];
                    final colorPalette = [
                      const Color(0xFF071E22),
                      const Color(0xFF1D7874),
                    ];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      color: colorPalette[index % colorPalette.length],
                      child: ListTile(
                        title: Text(
                          univ.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          univ.website,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                        onTap: () {
                          launch(univ.website);
                          // Membuka website universitas di browser eksternal ketika ListTile diklik
                        },
                      ),
                    );
                  },
                );
              } else {
                // Menampilkan indicator loading jika daftar universitas kosong
                return const CircularProgressIndicator();
              }
            },
          ),
        ),
      ),
    );
  }
}
