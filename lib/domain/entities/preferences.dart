enum MusicLevel { quiet, relaxing, energetic }

enum LuggageSize { smallBagOnly, standardSuitcase, largeItems }

enum ConversationLevel { quietRide, chatty }

class PreferencesEntity {
  final bool smokingAllowed;
  final bool petsAllowed;
  final MusicLevel musicLevel;
  final LuggageSize luggageSize;
  final ConversationLevel conversationLevel;

  const PreferencesEntity({
    this.smokingAllowed = false,
    this.petsAllowed = true,
    this.musicLevel = MusicLevel.relaxing,
    this.luggageSize = LuggageSize.standardSuitcase,
    this.conversationLevel = ConversationLevel.chatty,
  });

  PreferencesEntity copyWith({
    bool? smokingAllowed,
    bool? petsAllowed,
    MusicLevel? musicLevel,
    LuggageSize? luggageSize,
    ConversationLevel? conversationLevel,
  }) {
    return PreferencesEntity(
      smokingAllowed: smokingAllowed ?? this.smokingAllowed,
      petsAllowed: petsAllowed ?? this.petsAllowed,
      musicLevel: musicLevel ?? this.musicLevel,
      luggageSize: luggageSize ?? this.luggageSize,
      conversationLevel: conversationLevel ?? this.conversationLevel,
    );
  }
}
