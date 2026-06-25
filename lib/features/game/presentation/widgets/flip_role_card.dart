import 'package:flutter/material.dart';

import 'character_flip_card.dart';
import '../../domain/entities/session_player_entity.dart';

class FlipRoleCard extends StatelessWidget {
  const FlipRoleCard({
    super.key,
    required this.player,
    required this.isRevealed,
  });

  final SessionPlayerEntity player;
  final bool isRevealed;

  @override
  Widget build(BuildContext context) {
    return CharacterFlipCard(
      key: key,
      player: player,
      isRevealed: isRevealed,
    );
  }
}
