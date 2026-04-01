class Emoji {
  final String code;
  final String placeholder;
  final String display;

  Emoji({required this.code, required this.placeholder, required this.display});
}

class EmojiList {
  static List<Emoji> get emojis {
    return [
      Emoji(code: '😊', placeholder: '[smile]', display: '😊'),
      Emoji(code: '😂', placeholder: '[laugh]', display: '😂'),
      Emoji(code: '❤️', placeholder: '[heart]', display: '❤️'),
      Emoji(code: '👍', placeholder: '[thumbsup]', display: '👍'),
      Emoji(code: '🎉', placeholder: '[party]', display: '🎉'),
      Emoji(code: '🔥', placeholder: '[fire]', display: '🔥'),
      Emoji(code: '😍', placeholder: '[love]', display: '😍'),
      Emoji(code: '🤔', placeholder: '[think]', display: '🤔'),
      Emoji(code: '😢', placeholder: '[cry]', display: '😢'),
      Emoji(code: '😡', placeholder: '[angry]', display: '😡'),
      Emoji(code: '🤣', placeholder: '[rofl]', display: '🤣'),
      Emoji(code: '😎', placeholder: '[cool]', display: '😎'),
      Emoji(code: '🤩', placeholder: '[star]', display: '🤩'),
      Emoji(code: '🤗', placeholder: '[hug]', display: '🤗'),
      Emoji(code: '🤫', placeholder: '[shush]', display: '🤫'),
      Emoji(code: '🤔', placeholder: '[think]', display: '🤔'),
      Emoji(code: '😴', placeholder: '[sleep]', display: '😴'),
      Emoji(code: '😷', placeholder: '[mask]', display: '😷'),
      Emoji(code: '🤒', placeholder: '[sick]', display: '🤒'),
      Emoji(code: '🤕', placeholder: '[injured]', display: '🤕'),
    ];
  }

  static String replacePlaceholders(String text) {
    String result = text;
    for (var emoji in emojis) {
      result = result.replaceAll(emoji.placeholder, emoji.code);
    }
    return result;
  }

  static String replaceEmojisWithPlaceholders(String text) {
    String result = text;
    for (var emoji in emojis) {
      result = result.replaceAll(emoji.code, emoji.placeholder);
    }
    return result;
  }
}
