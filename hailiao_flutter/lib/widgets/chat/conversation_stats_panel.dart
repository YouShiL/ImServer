import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/common_tokens.dart';
import 'package:hailiao_flutter/theme/conversation_ui_tokens.dart';

class ConversationStatsPanel extends StatelessWidget {
  const ConversationStatsPanel({
    super.key,
    required this.summaryText,
    required this.currentSortLabel,
    required this.sortOptions,
    required this.onSortSelected,
    required this.onReset,
    required this.stats,
  });

  final String summaryText;
  final String currentSortLabel;
  final List<String> sortOptions;
  final ValueChanged<String> onSortSelected;
  final VoidCallback onReset;
  final List<ConversationStatData> stats;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ConversationUiTokens.statsPanelMaxWidth,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: CommonTokens.sm,
            vertical: CommonTokens.xs,
          ),
          decoration: BoxDecoration(
            color: ConversationUiTokens.statsPanelBackground,
            borderRadius: BorderRadius.circular(ConversationUiTokens.radiusMd),
            border: Border.all(color: ConversationUiTokens.statsPanelBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      summaryText,
                      style: ConversationUiTokens.statsSummaryTextStyle.copyWith(
                        color: ConversationUiTokens.statsSummaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: '排序',
                    onSelected: onSortSelected,
                    itemBuilder: (context) => sortOptions
                        .map(
                          (option) => CheckedPopupMenuItem<String>(
                            value: option,
                            checked: currentSortLabel == option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.sort_rounded,
                          size: 18,
                          color: ConversationUiTokens.searchBarIcon,
                        ),
                        const SizedBox(width: CommonTokens.xxs),
                        Text(
                          currentSortLabel,
                          style:
                              ConversationUiTokens.statsActionTextStyle.copyWith(
                            color: ConversationUiTokens.statsSummaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: CommonTokens.xs),
                  TextButton(
                    onPressed: onReset,
                    child: Text(
                      '重置',
                      style:
                          ConversationUiTokens.statsActionTextStyle.copyWith(
                        color: ConversationUiTokens.statsActionText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CommonTokens.xs),
              Wrap(
                spacing: CommonTokens.xs,
                runSpacing: CommonTokens.xs,
                children: stats
                    .map(
                      (item) => _StatChip(
                        label: item.label,
                        value: item.value,
                        valueColor: item.valueColor,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConversationStatData {
  const ConversationStatData({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ConversationUiTokens.statsChipBackground,
        borderRadius: BorderRadius.circular(CommonTokens.pillRadius),
        border: Border.all(color: ConversationUiTokens.statsChipBorder),
      ),
      child: RichText(
        text: TextSpan(
          style: CommonTokens.caption.copyWith(
            color: ConversationUiTokens.statsChipText,
          ),
          children: <InlineSpan>[
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: CommonTokens.bodySmall.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
