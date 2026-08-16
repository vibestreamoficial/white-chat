import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Upload de midia (video, foto, avatar) para o Firebase Storage.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({
    required File file,
    required String folder,
    String? uid,
    String ext = 'mp4',
  }) async {
    final safe = uid ?? 'anon';
    final name = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('$folder/$safe/$name');
    final task = ref.putFile(file);
    await task;
    return ref.getDownloadURL();
  }

  Future<String> uploadBytes({
    required List<int> bytes,
    required String folder,
    String? uid,
    String ext = 'png',
  }) async {
    final safe = uid ?? 'anon';
    final name = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('$folder/$safe/$name');
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }
}
