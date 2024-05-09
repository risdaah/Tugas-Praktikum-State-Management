// Impor paket Flutter untuk UI
import 'package:flutter/material.dart';
// Impor paket HTTP untuk mengambil data dari server
import 'package:http/http.dart' as http;
// Impor paket untuk mengonversi data JSON
import 'dart:convert';
// Impor paket untuk membuka URL di browser
import 'package:url_launcher/url_launcher.dart';
// Impor paket untuk manajemen keadaan aplikasi
import 'package:provider/provider.dart';

// Kelas untuk merepresentasikan sebuah universitas
class Univ {
  String name; // Nama universitas
  String website; // Website universitas

  // Konstruktor untuk inisialisasi objek universitas
  Univ({required this.name, required this.website});
}

// Kelas untuk menyediakan data universitas dan mengelola keadaan aplikasi
class UniversityProvider extends ChangeNotifier {
  late Future<List<Univ>> futureUniversities; // Future untuk daftar universitas

  String baseUrl =
      "http://universities.hipolabs.com/search?country="; // URL dasar API
  String negara = "Indonesia"; // Negara default

  // Konstruktor untuk inisialisasi provider universitas
  UniversityProvider() {
    futureUniversities =
        fetchData(negara); // Memuat data universitas pertama kali
  }

  // Metode untuk mengambil data universitas dari server
  Future<List<Univ>> fetchData(String country) async {
    final response =
        await http.get(Uri.parse(baseUrl + country)); // Permintaan HTTP ke API

    if (response.statusCode == 200) {
      // Jika permintaan berhasil
      List<dynamic> data = jsonDecode(response.body); // Mendekodekan data JSON
      List<Univ> universities = [];

      // Melooping data untuk membuat objek universitas
      for (var item in data) {
        universities.add(Univ(
          name: item['name'],
          website: item['web_pages'][0],
        ));
      }

      return universities; // Mengembalikan daftar universitas
    } else {
      throw Exception(
          'Failed to load data'); // Jika permintaan gagal, lempar pengecualian
    }
  }

  // Metode untuk memperbarui negara dan memuat ulang data universitas
  void updateCountry(String newCountry) {
    negara = newCountry; // Memperbarui negara
    futureUniversities = fetchData(negara); // Memuat ulang data universitas
    // Memberitahu widget yang menggunakan provider bahwa keadaan telah berubah
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      // Membuat provider universitas
      create: (context) => UniversityProvider(),
      child: const MyApp(),
    ),
  );
}

// Widget utama aplikasi Flutter
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
            // Dropdown menu untuk memilih negara
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: context.watch<UniversityProvider>().negara,
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
                      context.read<UniversityProvider>().updateCountry(
                          newValue); // Memperbarui negara saat pilihan diubah
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: Consumer<UniversityProvider>(
            builder: (context, universityProvider, child) {
              return FutureBuilder<List<Univ>>(
                future: universityProvider.futureUniversities,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    // Jika data universitas tersedia
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final univ = snapshot.data![index];
                        final colorPalette = [
                          const Color(0xFF071E22),
                          const Color(0xFF1D7874),
                        ];

                        // Membangun tampilan untuk setiap universitas
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
                              // Membuka website universitas saat diklik
                            },
                          ),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    // Jika terjadi kesalahan
                    return Text('${snapshot.error}');
                    // Menampilkan pesan kesalahan
                  }
                  // Menampilkan indikator loading
                  return const CircularProgressIndicator();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
