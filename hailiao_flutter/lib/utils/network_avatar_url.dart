/// 头像等场景共用的网络地址判定：仅当 [Uri.tryParse] 得到 `http`/`https` scheme 时视为可交给 [Image.network]。
/// 与会话列表、好友行、资料头等处的历史规则一致（trim 后空串视为无效）。
bool isHttpOrHttpsAvatarUrl(String? raw) {
  final String t = (raw ?? '').trim();
  if (t.isEmpty) {
    return false;
  }
  final Uri? u = Uri.tryParse(t);
  return u != null && u.hasScheme && (u.scheme == 'http' || u.scheme == 'https');
}

/// 返回已 trim 的可加载 URL，否则 `null`（供传入 `imageUrl` / 会话侧快照等）。
String? httpOrHttpsAvatarUrlOrNull(String? raw) {
  final String t = (raw ?? '').trim();
  if (!isHttpOrHttpsAvatarUrl(t)) {
    return null;
  }
  return t;
}
