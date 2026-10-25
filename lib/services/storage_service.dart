import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/poem.dart';

class StorageService {
  static const String _poemsKey = 'saved_poems';

  Future<List<Poem>> getPoems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? poemsJson = prefs.getString(_poemsKey);
    if (poemsJson == null || poemsJson.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(poemsJson);
      return decoded.map((item) => Poem.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> savePoems(List<Poem> poems) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(poems.map((p) => p.toMap()).toList());
    await prefs.setString(_poemsKey, encoded);
  }

  Future<void> savePoem(Poem poem) async {
    final poems = await getPoems();
    final index = poems.indexWhere((p) => p.id == poem.id);
    if (index >= 0) {
      poems[index] = poem;
    } else {
      poems.insert(0, poem);
    }
    await savePoems(poems);
  }

  Future<void> deletePoem(String id) async {
    final poems = await getPoems();
    poems.removeWhere((p) => p.id == id);
    await savePoems(poems);
  }
}
