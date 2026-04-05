import 'package:flutter/material.dart';

class ChatBlockedBanner extends StatelessWidget {
  const ChatBlockedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFFF3E0),
      child: const Row(
        children: <Widget>[
          Icon(Icons.block_outlined, size: 18, color: Color(0xFFB45309)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '\u7531\u4e8e\u4f60\u5df2\u62c9\u9ed1\u8be5\u7528\u6237\uff0c\u5f53\u524d\u65e0\u6cd5\u53d1\u9001\u6d88\u606f\u3002',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
