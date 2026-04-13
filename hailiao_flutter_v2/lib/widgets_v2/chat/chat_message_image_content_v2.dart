import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hailiao_flutter/services/api_service.dart';
import 'package:hailiao_flutter_v2/domain_v2/entities/message_send_state.dart';
import 'package:hailiao_flutter_v2/screens_v2/chat/image_preview_v2_page.dart';
import 'package:hailiao_flutter_v2/theme/chat_v2_tokens.dart';

class ChatMessageImageContentV2 extends StatelessWidget {
  const ChatMessageImageContentV2({
    super.key,
    required this.imageUrl,
    required this.sendState,
    required this.isMine,
  });

  final String imageUrl;
  final MessageSendState sendState;
  final bool isMine;

  static const double _boxW = 180;
  static const double _boxH = 128;

  String _resolvedUrl(String raw) {
    final String t = raw.trim();
    if (t.isEmpty) {
      return '';
    }
    if (t.startsWith('http://') || t.startsWith('https://')) {
      return t;
    }
    final String base = ApiService.baseUrl;
    if (base.endsWith('/')) {
      return '${base.substring(0, base.length - 1)}$t';
    }
    return '$base$t';
  }

  /// 与预览页一致：忽略 query，减轻 OSS 预签名仅参数变化导致的缓存未命中。
  static String _diskCacheKey(String url) {
    final String t = url.trim();
    if (t.isEmpty) {
      return t;
    }
    final int q = t.indexOf('?');
    return q >= 0 ? t.substring(0, q) : t;
  }

  @override
  Widget build(BuildContext context) {
    final String url = _resolvedUrl(imageUrl);
    final bool canOpenPreview =
        url.isNotEmpty &&
        sendState != MessageSendState.sending &&
        sendState != MessageSendState.failed;

    return GestureDetector(
      onTap: !canOpenPreview
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ImagePreviewV2Page(imageUrl: imageUrl),
                ),
              );
            },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: _boxW,
          height: _boxH,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (url.isEmpty)
                _errorPlaceholder('无法解析图片地址')
              else
                CachedNetworkImage(
                  imageUrl: url,
                  cacheKey: _diskCacheKey(url),
                  fit: BoxFit.cover,
                  placeholder: (BuildContext context, String url) =>
                      _loadingPlaceholder(),
                  errorWidget:
                      (BuildContext context, String url, dynamic error) =>
                          _errorPlaceholder('图片加载失败'),
                ),
              if (isMine && sendState == MessageSendState.sending)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (isMine && sendState == MessageSendState.failed)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: const Color(0xCCB91C1C),
                    child: const Text(
                      '发送失败',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingPlaceholder() {
    return ColoredBox(
      color: const Color(0xFFE5E7EB),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ChatV2Tokens.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _errorPlaceholder(String message) {
    return ColoredBox(
      color: const Color(0xFFE5E7EB),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.broken_image_outlined,
              size: 36,
              color: ChatV2Tokens.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ChatV2Tokens.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
