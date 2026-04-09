/// IM 渐进迁移：只读开关（Phase 0），与后端 `im.*` 语义对齐，供 UI/Provider 后续只读使用。
///
/// 默认值与 **legacy** 行为一致。可选通过 `--dart-define` 注入（例如 CI/本地试验）。
library;

abstract final class ImFeatureFlags {
  ImFeatureFlags._();

  static const String _kMigrationMode =
      String.fromEnvironment('IM_MIGRATION_MODE', defaultValue: '');

  static const String _kWukongEnabled =
      String.fromEnvironment('IM_WUKONG_ENABLED', defaultValue: '');

  static const String _kWebhookEnabled =
      String.fromEnvironment('IM_WEBHOOK_ENABLED', defaultValue: '');

  static const String _kSendViaServer =
      String.fromEnvironment('IM_SEND_VIA_SERVER', defaultValue: '');

  static const String _kClientDirectSendFallback = String.fromEnvironment(
    'IM_CLIENT_DIRECT_SEND_FALLBACK',
    defaultValue: '',
  );

  /// 对应后端 `im.migration.mode`；未定义时为 `legacy`。
  static String get migrationMode {
    final v = _kMigrationMode.trim();
    return v.isEmpty ? 'legacy' : v;
  }

  /// 对应后端 `im.wukong.enabled`；未定义时视为 false。
  static bool get wukongEnabled => _parseBool(_kWukongEnabled, defaultValue: false);

  /// 对应后端 `im.webhook.enabled`；未定义时视为 false。
  static bool get webhookEnabled =>
      _parseBool(_kWebhookEnabled, defaultValue: false);

  /// 对应后端 `im.send.via-server`；未定义时视为 false。
  static bool get sendViaServer =>
      _parseBool(_kSendViaServer, defaultValue: false);

  /// 对应后端 `im.client.direct-send-fallback`；未定义时视为 true（legacy）。
  static bool get clientDirectSendFallback => _parseBool(
        _kClientDirectSendFallback,
        defaultValue: true,
      );

  /// `IM_SEND_VIA_SERVER=true` 且 `IM_CLIENT_DIRECT_SEND_FALLBACK=false`：聊天页不再在 REST 成功后本地 `sendTextMessage`。
  static bool get omitClientDirectImAfterRest =>
      sendViaServer && !clientDirectSendFallback;

  static bool _parseBool(String raw, {required bool defaultValue}) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) {
      return defaultValue;
    }
    return v == '1' || v == 'true' || v == 'yes';
  }
}
