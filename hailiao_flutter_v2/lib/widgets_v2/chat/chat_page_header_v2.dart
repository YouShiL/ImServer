import 'package:flutter/material.dart';
import 'package:hailiao_flutter_v2/adapters/chat_v2_view_models.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class ChatPageHeaderV2 extends StatelessWidget {
  const ChatPageHeaderV2({
    super.key,
    required this.viewModel,
  });

  final ChatV2HeaderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ChatV2Tokens.headerHeight,
      decoration: const BoxDecoration(
        color: ChatV2Tokens.headerBackground,
        border: Border(bottom: BorderSide(color: ChatV2Tokens.divider)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ChatV2Tokens.horizontalPadding,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  viewModel.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChatV2Tokens.headerTitle,
                ),
                if ((viewModel.subtitle ?? '').isNotEmpty)
                  Text(
                    viewModel.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChatV2Tokens.headerSubtitle,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
