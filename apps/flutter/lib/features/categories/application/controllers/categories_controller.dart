import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/categories/application/state/categories_state.dart";
import "package:ownfinances/features/categories/data/repositories/category_repository.dart";

class CategoriesController extends ChangeNotifier {
  final CategoryRepository repository;
  CategoriesState _state = CategoriesState.initial;

  CategoriesController(this.repository);

  CategoriesState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final result = await repository.list(isActive: true);
      _state = _state.copyWith(isLoading: false, items: result.results);
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  Future<String?> create({
    required String name,
    required String kind,
    String? parentId,
    String? color,
    String? icon,
    bool isActive = true,
  }) async {
    try {
      final created = await repository.create(
        name: name,
        kind: kind,
        parentId: parentId,
        color: color,
        icon: icon,
        isActive: isActive,
      );
      final next = [..._state.items, created]
        ..sort((a, b) => a.name.compareTo(b.name));
      _state = _state.copyWith(items: next);
      notifyListeners();
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<String?> update({
    required String id,
    required String name,
    required String kind,
    String? parentId,
    String? color,
    String? icon,
    required bool isActive,
  }) async {
    try {
      final updated = await repository.update(
        id,
        name: name,
        kind: kind,
        parentId: parentId,
        color: color,
        icon: icon,
        isActive: isActive,
      );
      final next =
          _state.items.map((item) => item.id == id ? updated : item).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      _state = _state.copyWith(items: next);
      notifyListeners();
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<String?> remove(String id) async {
    try {
      await repository.delete(id);
      _state = _state.copyWith(
        items: _state.items.where((item) => item.id != id).toList(),
      );
      notifyListeners();
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Erro inesperado";
  }
}
