import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../firebase_options.dart';

/// Upload de midia (video, foto, avatar) para o Firebase Storage.
class StorageService {
  FirebaseStorage? _storage;

  bool get _demoMode => !DefaultFirebaseOptions.configured;

  FirebaseStorage get _firebaseStorage {
    if (_demoMode) {
      throw StateError(
          'Upload de midia disponivel somente com o Firebase configurado.');
    }
    return _storage ??= FirebaseStorage.instance;
  }

  Future<String> uploadFile({
    required File file,
    required String folder,
    String? uid,
    String ext = 'mp4',
  }) async {
    final safe = uid ?? 'anon';
    final name = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _firebaseStorage.ref().child('$folder/$safe/$name');
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
    final ref = _firebaseStorage.ref().child('$folder/$safe/$name');
    await ref.putData(Uint8List.fromList(bytes));
    return ref.getDownloadURL();
  }
}
