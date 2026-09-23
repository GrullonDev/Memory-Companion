import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty.dart';

/// Lee y escribe el [SkillState] de cada categoría — nivel incluido — en la
/// base local.
///
/// Sin red y sin cuenta. Una categoría sin fila no se siembra: el motor
/// adaptativo ya sabe cuál es su estado inicial.
class SkillRepository {
  SkillRepository({required AppDatabase database, DateTime Function()? clock})
    : _db = database,
      _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Todas las categorías jugadas alguna vez, por `GameCategory.id`.
  Future<Map<String, SkillState>> readAll() async {
    final rows = await _db.select(_db.categoryLevels).get();
    return {for (final row in rows) row.categoryId: _fromRow(row)};
  }

  Future<void> save(String categoryId, SkillState state) {
    return _db
        .into(_db.categoryLevels)
        .insertOnConflictUpdate(
          CategoryLevelsCompanion.insert(
            categoryId: categoryId,
            level: Value(state.level),
            skill: state.skill,
            pairCount: state.pairCount,
            consecutiveLosses: Value(state.consecutiveLosses),
            roundsPlayed: Value(state.roundsPlayed),
            updatedAt: _now().millisecondsSinceEpoch,
          ),
        );
  }

  static SkillState _fromRow(CategoryLevelRow row) {
    return SkillState(
      skill: row.skill,
      pairCount: row.pairCount,
      consecutiveLosses: row.consecutiveLosses,
      roundsPlayed: row.roundsPlayed,
      level: row.level,
    );
  }
}
