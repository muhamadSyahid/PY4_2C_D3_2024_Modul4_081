import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_081/features/logbook/models/log_model.dart';
import 'package:logbook_app_081/services/mongo_service.dart';

void main() {
  final MongoService mongoService = MongoService();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    await mongoService.connect();
  });

  tearDownAll(() async {
    await mongoService.close();
  });

  test(
    'Positive: menyimpan data log ke cloud service dan memverifikasi data tersimpan',
    () async {
      // Test Case ID: TC03
      // Modul Uji: insertLog()
      // Test Type: Positif
      // Nama Test Case: Save Data to Cloud Service
      // Prekondisi: Koneksi MongoDB Atlas tersedia dan koleksi logs siap digunakan.
      // Langkah Pengujian: Panggil insertLog dengan data log baru lalu verifikasi data tersimpan.
      // Data Test: user="tester_cloud", title="Cloud Save Test", description="Data log untuk validasi penyimpanan cloud"
      // Ekspektasi: Data berhasil disimpan di cloud dan bisa ditemukan kembali.

      final String uniqueTitle =
          'Cloud Save Test ${DateTime.now().millisecondsSinceEpoch}';
      final LogModel testLog = LogModel(
        id: ObjectId(),
        user: 'tester_cloud',
        title: uniqueTitle,
        description: 'Data log untuk validasi penyimpanan cloud',
        date: DateTime.now(),
        category: 'Testing',
      );

      try {
        await mongoService.insertLog(testLog);

        final List<LogModel> logs = await mongoService.getLogs();
        final List<LogModel> insertedLogs = logs
            .where(
              (LogModel log) =>
                  log.title == uniqueTitle && log.user == 'tester_cloud',
            )
            .toList();

        expect(insertedLogs, isNotEmpty);
        expect(insertedLogs.first.title, uniqueTitle);
        expect(insertedLogs.first.user, 'tester_cloud');
        expect(
          insertedLogs.first.description,
          'Data log untuk validasi penyimpanan cloud',
        );
        expect(insertedLogs.first.category, 'Testing');
      } finally {
        final List<LogModel> logs = await mongoService.getLogs();
        final List<LogModel> insertedLogs = logs
            .where(
              (LogModel log) =>
                  log.title == uniqueTitle && log.user == 'tester_cloud',
            )
            .toList();

        if (insertedLogs.isNotEmpty && insertedLogs.first.id != null) {
          await mongoService.deleteLog(insertedLogs.first.id!);
        }
      }
    },
  );
}
