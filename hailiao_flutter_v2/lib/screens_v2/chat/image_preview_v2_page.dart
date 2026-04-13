import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hailiao_flutter/services/api_service.dart';

/// 全屏图片预览（最小版：深色底 + 居中图 + 返回）。
class ImagePreviewV2Page extends StatelessWidget {
  const ImagePreviewV2Page({
    super.key,
    required this.imageUrl,
  });

  /// 可为相对路径，内部会拼 [ApiService.baseUrl]。
  final String imageUrl;

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

  /// 与气泡内缩略图一致，便于列表已缓存后预览走同一磁盘条目。
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: url.isEmpty
            ? const Text(
                '无法预览',
                style: TextStyle(color: Colors.white70),
              )
            : InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: url,
                  cacheKey: _diskCacheKey(url),
                  fit: BoxFit.contain,
                  placeholder: (BuildContext context, String url) =>
                      const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2,
                    ),
                  ),
                  errorWidget:
                      (BuildContext context, String url, dynamic error) =>
                          const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      '图片加载失败',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
