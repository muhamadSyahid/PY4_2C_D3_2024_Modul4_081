import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logbook_app_081/helpers/log_helper.dart';
import 'package:logbook_app_081/services/mongo_service.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_081/features/logbook/models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  static const String _storageKey = 'user_logs_data';

  List<LogModel> getLogsByUser(String currentUser) {
    return logsNotifier.value.where((log) => log.user == currentUser).toList();
  }

  LogController() {
    loadFromDisk();
  }

  // void addLog(String user, String title, String desc, String category) {
  //   final newLog = LogModel(
  //     user: user,
  //     title: title,
  //     description: desc,
  //     category: category,
  //     date: DateTime.now(),
  //   );
  //   logsNotifier.value = [...logsNotifier.value, newLog];
  //   saveToDisk();
  // }

  // void updateLog(
  //     int index, String user, String title, String desc, String category) {
  //   final currentLogs = List<LogModel>.from(logsNotifier.value);
  //   currentLogs[index] = LogModel(
  //     user: user,
  //     title: title,
  //     description: desc,
  //     category: category,
  //     date: DateTime.now(),
  //   );
  //   logsNotifier.value = currentLogs;
  //   saveToDisk();
  // }

  // void removeLog(int index) {
  //   final currentLogs = List<LogModel>.from(logsNotifier.value);
  //   currentLogs.removeAt(index);
  //   logsNotifier.value = currentLogs;
  //   saveToDisk();
  // }

  // Future<void> saveToDisk() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final String encodedData =
  //       jsonEncode(logsNotifier.value.map((e) => e.toMap()).toList());
  //   await prefs.setString(_storageKey, encodedData);
  // }

  // Future<void> loadFromDisk() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final String? data = prefs.getString(_storageKey);
  //   if (data != null) {
  //     final List decoded = jsonDecode(data);
  //     logsNotifier.value = decoded.map((e) => LogModel.fromMap(e)).toList();
  //   }
  // }

  Future<void> addLog(String user, String title, String desc, String category) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      date: DateTime.now(), 
      user: user, 
      category: category,
    );

    try {
      // 2. Kirim ke MongoDB Atlas
      await MongoService().insertLog(newLog);

      // 3. Update UI Lokal (Data sekarang sudah punya ID asli)
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.add(newLog);
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog(
        "SUCCESS: Tambah data dengan ID lokal",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog("ERROR: Gagal sinkronisasi Add - $e", level: 1);
    }
  }

  // 2. Memperbarui data di Cloud (HOTS: Sinkronisasi Terjamin)
  Future<void> updateLog(int index, String newTitle, String newDesc, String newCat) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    final updatedLog = LogModel(
      id: oldLog.id, // ID harus tetap sama agar MongoDB mengenali dokumen ini
      title: newTitle,
      description: newDesc,
      date: DateTime.now(), 
      user: oldLog.user, 
      category: newCat,
    );

    try {
      // 1. Jalankan update di MongoService (Tunggu konfirmasi Cloud)
      await MongoService().updateLog(updatedLog);

      // 2. Jika sukses, baru perbarui state lokal
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Update '${oldLog.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Update - $e",
        source: "log_controller.dart",
        level: 1,
      );
      // Data di UI tidak berubah jika proses di Cloud gagal
    }
  }

  // 3. Menghapus data dari Cloud (HOTS: Sinkronisasi Terjamin)
  Future<void> removeLog(int index) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final targetLog = currentLogs[index];

    try {
      if (targetLog.id == null) {
        throw Exception(
          "ID Log tidak ditemukan, tidak bisa menghapus di Cloud.",
        );
      }

      // 1. Hapus data di MongoDB Atlas (Tunggu konfirmasi Cloud)
      await MongoService().deleteLog(targetLog.id!);

      // 2. Jika sukses, baru hapus dari state lokal
      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Hapus '${targetLog.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Hapus - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // --- BARU: FUNGSI PERSISTENCE (SINKRONISASI JSON) ---

  // Fungsi untuk menyimpan seluruh List ke penyimpanan lokal
  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    // Mengubah List of Object -> List of Map -> String JSON
    final String encodedData = jsonEncode(
      logsNotifier.value.map((log) => log.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encodedData);
  }

  // Ganti pemanggilan SharedPreferences menjadi MongoService
  Future<void> loadFromDisk() async {
    // Mengambil dari Cloud, bukan lokal
    final cloudData = await MongoService().getLogs();
    logsNotifier.value = cloudData;
  }
}
