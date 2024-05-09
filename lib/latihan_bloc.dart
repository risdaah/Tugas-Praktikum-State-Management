// Import library yang diperlukan

// Library untuk membuat UI dengan Material Design
import 'package:flutter/material.dart';
// Library untuk mengubah data JSON menjadi objek Dart
import 'dart:convert';
// Library untuk melakukan HTTP requests
import 'package:http/http.dart' as http;
// Library untuk state management menggunakan Bloc
import 'package:flutter_bloc/flutter_bloc.dart';
// Library untuk membuka URL
import 'package:url_launcher/url_launcher.dart';

// Model untuk menyimpan data universitas
class University {
  final String name; // Nama universitas
  final String website; // Website universitas

  University({
    required this.name,
    required this.website,
  });

  // Konstruktor factory untuk membuat objek University dari JSON
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'], // Mendapatkan nama universitas dari JSON
      website: json['web_pages']
          [0], // Mendapatkan website universitas dari JSON
    );
  }
}

// Abstract class untuk event-event yang terjadi pada Bloc
abstract class UniversityEvent {}

// Event untuk mengambil data universitas berdasarkan negara
class FetchUniversitiesEvent extends UniversityEvent {
  final String country; // Negara tempat universitas berada
  FetchUniversitiesEvent(this.country); // Konstruktor dengan parameter negara
}

// Bloc untuk mengelola state aplikasi terkait data universitas
class UniversityBloc extends Bloc<UniversityEvent, List<University>> {
  // Konstruktor untuk UniversityBloc
  UniversityBloc() : super([]) {
    on<FetchUniversitiesEvent>(
        _fetchUniversities); // Menangani event FetchUniversitiesEvent
  }

  // Method async untuk mengambil data universitas dari API
  Future<void> _fetchUniversities(
    FetchUniversitiesEvent event,
    Emitter<List<University>> emit,
  ) async {
    try {
      final universities = await _fetchUniversitiesFromApi(
          event.country); // Mendapatkan data universitas dari API
      emit(universities); // Mengirim data universitas ke Bloc
    } catch (e) {
      print('Error: $e'); // Menampilkan error jika terjadi
      emit([]); // Mengirim data kosong ke Bloc jika terjadi error
    }
  }

  // Method async untuk mengambil data universitas dari API berdasarkan negara
  Future<List<University>> _fetchUniversitiesFromApi(String country) async {
    final response = await http.get(
        Uri.parse('http://universities.hipolabs.com/search?country=$country'));
    // Melakukan HTTP GET request ke API

    if (response.statusCode == 200) {
      final List<dynamic> data =
          jsonDecode(response.body); // Mendapatkan data JSON dari response
      return data
          .map((json) => University.fromJson(json))
          .toList(); // Mengubah data JSON menjadi list objek University
    } else {
      throw Exception('Failed to load universities data');
      // Melempar exception jika gagal mengambil data universitas
    }
  }
}

// Method main, fungsi utama untuk menjalankan aplikasi Flutter
void main() {
  runApp(MyApp()); // Menjalankan aplikasi Flutter
}

// Widget MyApp, sebagai root dari aplikasi Flutter
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (context) => UniversityBloc(),
        // Membuat instance UniversityBloc dan menyediakan ke widget-tree
        child: UniversitiesPage(), // Menampilkan halaman UniversitiesPage
      ),
    );
  }
}

// Widget UniversitiesPage, halaman utama aplikasi untuk menampilkan data universitas
class UniversitiesPage extends StatefulWidget {
  @override
  _UniversitiesPageState createState() => _UniversitiesPageState();
}

// State dari widget UniversitiesPage
class _UniversitiesPageState extends State<UniversitiesPage> {
  final List<String> _aseanCountries = [
    // List negara-negara di ASEAN
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
  ];

  String _selectedCountry =
      'Indonesia'; // Negara terpilih, defaultnya Indonesia

  @override
  void initState() {
    super.initState();
    context.read<UniversityBloc>().add(FetchUniversitiesEvent(
        _selectedCountry)); // Mengambil data universitas saat halaman dimuat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Universitas ASEAN'), // Judul aplikasi
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedCountry,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCountry =
                      newValue!; // Mengubah negara terpilih saat dropdown diganti
                  context
                      .read<UniversityBloc>()
                      .add(FetchUniversitiesEvent(newValue));
                  // Mengambil data universitas berdasarkan negara terpilih
                });
              },
              items: _aseanCountries
                  .map<DropdownMenuItem<String>>(
                      (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                  .toList(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          BlocBuilder<UniversityBloc, List<University>>(
            builder: (context, universities) {
              if (universities.isEmpty) {
                return const Center(child: CircularProgressIndicator());
                // Menampilkan indicator loading jika data kosong
              }
              return Expanded(
                child: ListView.builder(
                  itemCount: universities.length,
                  itemBuilder: (context, index) {
                    final university =
                        universities[index]; // Mendapatkan objek University
                    final colorPalette = [
                      const Color(0xFF071E22),
                      const Color(0xFF1D7874),
                    ];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      color: colorPalette[index %
                          colorPalette.length], // Menggunakan warna dari palet
                      child: ListTile(
                        title: Text(
                          university.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          university.website,
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
                          launch(university.website);
                          // Membuka URL website universitas saat tombol di klik
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
