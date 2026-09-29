import 'package:cloud_firestore/cloud_firestore.dart';

/// The quick reactions a player can throw at their rival during a duel.
///
/// A fixed set rather than free text: nothing to moderate, and the security
/// rules can check the value against this list. Stored by [name], so adding
/// one here means adding it to `firestore.rules` too.
enum DuelReaction {
  thumbsUp('👍'),
  fire('🔥'),
  wow('😲'),
  laugh('😂');

  const DuelReaction(this.emoji);

  final String emoji;

  static DuelReaction? byName(Object? name) =>
      values.where((reaction) => reaction.name == name).firstOrNull;
}

/// A player's latest reaction, written under `reactions.<uid>` on the duel.
///
/// Like [DuelProgress], one small field overwritten on every send: the
/// rival only needs the newest one. [seq] grows with every send, so a
/// repeated snapshot never replays the animation.
class DuelReactionEvent {
  const DuelReactionEvent({required this.reaction, required this.seq, this.at});

  /// A new reaction sent now. The clock gives a [seq] that keeps growing
  /// across visits to the duel, unlike a counter kept in the page.
  factory DuelReactionEvent.now(DuelReaction reaction) => DuelReactionEvent(
    reaction: reaction,
    seq: DateTime.now().millisecondsSinceEpoch,
  );

  /// Null for a malformed or unknown reaction, which is simply not shown.
  static DuelReactionEvent? tryParse(Map<String, dynamic> data) {
    final reaction = DuelReaction.byName(data['reaction']);
    if (reaction == null) return null;
    final at = data['at'];
    return DuelReactionEvent(
      reaction: reaction,
      seq: (data['seq'] as num?)?.toInt() ?? 0,
      at: at is Timestamp ? at.toDate() : null,
    );
  }

  final DuelReaction reaction;
  final int seq;
  final DateTime? at;

  /// Written under `reactions.<uid>`; the time is the server's.
  Map<String, Object> toMap() => {'reaction': reaction.name, 'seq': seq};
}
