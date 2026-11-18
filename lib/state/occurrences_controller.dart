import 'package:aquawatt/data/prefs_repository.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:flutter/foundation.dart';

/// Ocorrências registradas pelo cidadão (anônimas, salvas só no dispositivo).
class OccurrencesController extends ChangeNotifier {
  OccurrencesController(PrefsRepository prefs)
      : _prefs = prefs,
        _items = prefs.loadOccurrences();

  final PrefsRepository _prefs;
  List<Occurrence> _items;

  /// Mais recentes primeiro.
  List<Occurrence> get items =>
      List.unmodifiable([..._items]..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  int get count => _items.length;

  Future<void> add({
    required String regionId,
    required OccurrenceCategory category,
    required String description,
  }) async {
    final now = DateTime.now();
    _items = [
      ..._items,
      Occurrence(
        id: now.microsecondsSinceEpoch.toString(),
        regionId: regionId,
        category: category,
        description: description.trim(),
        createdAt: now,
      ),
    ];
    notifyListeners();
    await _prefs.saveOccurrences(_items);
  }

  Future<void> remove(String id) async {
    _items = _items.where((o) => o.id != id).toList();
    notifyListeners();
    await _prefs.saveOccurrences(_items);
  }

  /// Limpa a memória após o apagamento dos dados locais.
  void reset() {
    _items = [];
    notifyListeners();
  }
}
