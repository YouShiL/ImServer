import 'package:flutter/material.dart';
import 'package:hailiao_flutter/theme/chat_ui_tokens.dart';

/// 己方文本气泡内容：单行短句与 Meta 同排（底对齐）；多行时**仅最后一行**与 meta 争宽，上方段落铺满 [maxW]。
class ChatOutgoingTextBubbleBody extends StatelessWidget {
  const ChatOutgoingTextBubbleBody({
    super.key,
    required this.text,
    required this.textStyle,
    required this.tailMeta,
  });

  final String text;
  final TextStyle textStyle;
  final Widget tailMeta;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxW = constraints.maxWidth;
        if (!maxW.isFinite || maxW <= 0) {
          return _wideStack(context, maxW: 240);
        }

        final TextScaler scaler = MediaQuery.textScalerOf(context);
        final TextDirection dir = Directionality.of(context);

        final double metaReserve =
            ChatUiTokens.chatOutgoingInlineMetaReserveWidth;
        final double singleLineTailGap =
            ChatUiTokens.outgoingSingleLineBodyToMetaGap;
        final double singleLineMetaBudget =
            ChatUiTokens.outgoingSingleLineInlineMetaWidthBudget;

        /// 无宽度限制下是否只有一「物理行」（不含自动换行，含显式 \\n 则为多行）。
        final TextPainter oneLine = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textDirection: dir,
          textScaler: scaler,
          maxLines: 1,
        )..layout(maxWidth: double.infinity);

        final bool isOnePhysicalLine = !oneLine.didExceedMaxLines;
        final double textW = oneLine.width;

        /// 单行且可与 meta 同排：外层 [ConstrainedBox] 只做 min/max clamp；内层 [IntrinsicWidth]+[Row] 随正文与 meta 真实占位收缩。
        /// 不得在此再包默认 [Align]（无 widthFactor 时会横向撑满 [maxW]，气泡仍会假宽）；右对齐交由外层气泡 [Column] 的 end。
        /// [outgoingSingleLineInlineMetaWidthBudget] 仅作是否进入本分支的预判，不参与最终宽度。
        if (isOnePhysicalLine &&
            textW + singleLineTailGap + singleLineMetaBudget <= maxW) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: ChatUiTokens.outgoingBubbleMinWidth,
              maxWidth: maxW,
            ),
            child: IntrinsicWidth(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(text, style: textStyle),
                  ),
                  SizedBox(width: singleLineTailGap),
                  tailMeta,
                ],
              ),
            ),
          );
        }

        /// 在气泡宽度下排版，用于区分「多可视行」与「单行但要给 meta 留位」。
        final TextPainter laidOut = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textDirection: dir,
          textScaler: scaler,
        )..layout(maxWidth: maxW);

        final List<LineMetrics> metrics = laidOut.computeLineMetrics();

        /// 仅一行可视：仍走「整块右侧让出 meta」（与旧行为一致，只影响这一行）。
        if (metrics.length <= 1) {
          return SizedBox(
            width: maxW,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topLeft,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: metaReserve),
                  child: Text(
                    text,
                    textAlign: TextAlign.start,
                    style: textStyle,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: tailMeta,
                ),
              ],
            ),
          );
        }

        /// 多行：首段至倒数行前 — 全宽；最后一行 — [Expanded] 内排版并与 meta 同排贴底。
        final int endOffset = text.isEmpty ? 0 : text.length - 1;
        final TextRange lastLineRange = laidOut.getLineBoundary(
          TextPosition(
            offset: endOffset,
            affinity: TextAffinity.downstream,
          ),
        );
        final int split = lastLineRange.start.clamp(0, text.length);
        final String prefix = text.substring(0, split);
        final String lastLine = text.substring(split);

        if (lastLine.isEmpty) {
          return SizedBox(
            width: maxW,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topLeft,
              children: <Widget>[
                Text(
                  prefix,
                  textAlign: TextAlign.start,
                  style: textStyle,
                ),
                Positioned(right: 0, bottom: 0, child: tailMeta),
              ],
            ),
          );
        }

        return SizedBox(
          width: maxW,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (prefix.isNotEmpty)
                Text(
                  prefix,
                  textAlign: TextAlign.start,
                  style: textStyle,
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      lastLine,
                      textAlign: TextAlign.start,
                      style: textStyle,
                    ),
                  ),
                  SizedBox(width: ChatUiTokens.metaTimeReceiptGap),
                  tailMeta,
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _wideStack(BuildContext context, {required double maxW}) {
    final double metaReserve =
        ChatUiTokens.chatOutgoingInlineMetaReserveWidth;
    return SizedBox(
      width: maxW,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topLeft,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: metaReserve),
            child: Text(text, textAlign: TextAlign.start, style: textStyle),
          ),
          Positioned(right: 0, bottom: 0, child: tailMeta),
        ],
      ),
    );
  }
}
