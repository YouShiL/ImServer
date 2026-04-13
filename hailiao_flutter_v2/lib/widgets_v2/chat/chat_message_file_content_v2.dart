import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class ChatMessageFileContentV2 extends StatelessWidget {
  const ChatMessageFileContentV2({
    super.key,
    required this.fileName,
  });

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 36,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D6),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.insert_drive_file_outlined, size: 20),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ChatV2Tokens.messageText,
          ),
        ),
      ],
    );
  }
}
