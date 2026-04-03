import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_081/services/mongo_service.dart';
import 'package:logbook_app_081/helpers/log_helper.dart';

void main() {
  const String sourceFile = "connection_test.dart";

  setUpAll(() async {
    // Memuat env sekali di awal untuk semua test
    await dotenv.load(fileName: ".env");
  });

  test(
    'Positive: memastikan koneksi ke MongoDB Atlas berhasil via MongoService',
    () async {
      // Test Case ID: TC01
      // Modul Uji: connect()
      // Test Type: Positif
      // Nama Test Case: Koneksi MongoDB Atlas
      // Prekondisi: File .env tersedia dan MONGODB_URI terisi valid.
      // Langkah Pengujian: Panggil connect() pada MongoService lalu verifikasi koneksi berhasil.
      // Data Test: MONGODB_URI dari file .env
      // Ekspektasi: Koneksi ke MongoDB Atlas berhasil dan tidak terjadi error.

      final mongoService = MongoService();

      // Memanfaatkan LogHelper baru yang sudah pakai dev.log dan print berwarna
      await LogHelper.writeLog(
        "--- START CONNECTION TEST ---",
        source: sourceFile,
      );

      try {
        // Mengetes koneksi
        await mongoService.connect();

        // Ekspektasi: URI tidak null dan koneksi berhasil
        expect(dotenv.env['MONGODB_URI'], isNotNull);

        await LogHelper.writeLog(
          "SUCCESS: Koneksi Atlas Terverifikasi",
          source: sourceFile,
          level: 2, // INFO (Hijau)
        );
      } catch (e) {
        await LogHelper.writeLog(
          "ERROR: Kegagalan koneksi - $e",
          source: sourceFile,
          level: 1, // ERROR (Merah)
        );
        fail("Koneksi gagal: $e");
      } finally {
        // Selalu tutup koneksi agar tidak menggantung di dashboard Atlas
        await mongoService.close();
        await LogHelper.writeLog("--- END TEST ---", source: sourceFile);
      }
    },
  );

  test(
    'Negative: koneksi MongoDB Atlas gagal saat URI tidak valid',
    () async {
      // Test Case ID: TC02
      // Modul Uji: connect()
      // Test Type: Negatif
      // Nama Test Case: Koneksi MongoDB Atlas dengan URI tidak valid
      // Prekondisi: File .env tersedia, lalu URI diganti sementara dengan nilai tidak valid.
      // Langkah Pengujian: Panggil connect() pada MongoService menggunakan URI invalid.
      // Data Test: MONGODB_URI invalid
      // Ekspektasi: Koneksi gagal dan method connect() melempar exception.

      final mongoService = MongoService();
      final originalUri = dotenv.env['MONGODB_URI'];
      const invalidUri = 'not-a-valid-mongodb-uri';

      await LogHelper.writeLog(
        "--- START CONNECTION TEST ---",
        source: sourceFile,
      );

      try {
        dotenv.env['MONGODB_URI'] = invalidUri;

        await expectLater(
          mongoService.connect(),
          throwsA(isA<MongoDartError>()),
        );

        await LogHelper.writeLog(
          "SUCCESS: Kegagalan koneksi terverifikasi",
          source: sourceFile,
          level: 2,
        );
      } finally {
        if (originalUri != null) {
          dotenv.env['MONGODB_URI'] = originalUri;
        }

        await mongoService.close();
        await LogHelper.writeLog("--- END TEST ---", source: sourceFile);
      }
    },
  );
}
