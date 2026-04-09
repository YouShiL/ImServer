package com.hailiao.api.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * IM 渐进迁移模块配置（Phase 0），前缀 {@code im.*}。
 * 默认值与当前线上行为一致：不落 WuKong、不关 webhook、客户端可直发 IM。
 */
@ConfigurationProperties(prefix = "im")
public class ImProperties {

    private Migration migration = new Migration();
    private Wukong wukong = new Wukong();
    private Webhook webhook = new Webhook();
    private Send send = new Send();
    private Client client = new Client();

    public Migration getMigration() {
        return migration;
    }

    public void setMigration(Migration migration) {
        this.migration = migration;
    }

    public Wukong getWukong() {
        return wukong;
    }

    public void setWukong(Wukong wukong) {
        this.wukong = wukong;
    }

    public Webhook getWebhook() {
        return webhook;
    }

    public void setWebhook(Webhook webhook) {
        this.webhook = webhook;
    }

    public Send getSend() {
        return send;
    }

    public void setSend(Send send) {
        this.send = send;
    }

    public Client getClient() {
        return client;
    }

    public void setClient(Client client) {
        this.client = client;
    }

    public static class Migration {
        /**
         * legacy | dual_write | server_im_primary（本轮仅记录，不参与分支）
         */
        private String mode = "legacy";

        public String getMode() {
            return mode;
        }

        public void setMode(String mode) {
            this.mode = mode;
        }
    }

    public static class Wukong {
        private boolean enabled = false;
        private String apiBaseUrl = "http://127.0.0.1:5001";
        private String managerToken = "";
        /**
         * 登录/注册/刷新 JWT 后是否向 WuKong Manager 注册 {@code /user/token}（与 {@link #enabled} 无关）。
         * 客户端 TCP 连接前必须在 WuKong 侧写入与 SDK 一致的 uid+token，否则会报 device token not found。
         */
        private boolean syncUserTokenOnAuth = true;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getApiBaseUrl() {
            return apiBaseUrl;
        }

        public void setApiBaseUrl(String apiBaseUrl) {
            this.apiBaseUrl = apiBaseUrl;
        }

        public String getManagerToken() {
            return managerToken;
        }

        public void setManagerToken(String managerToken) {
            this.managerToken = managerToken;
        }

        public boolean isSyncUserTokenOnAuth() {
            return syncUserTokenOnAuth;
        }

        public void setSyncUserTokenOnAuth(boolean syncUserTokenOnAuth) {
            this.syncUserTokenOnAuth = syncUserTokenOnAuth;
        }
    }

    public static class Webhook {
        private boolean enabled = false;
        private String path = "/api/im/webhook";
        private String secret = "";

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getPath() {
            return path;
        }

        public void setPath(String path) {
            this.path = path;
        }

        public String getSecret() {
            return secret;
        }

        public void setSecret(String secret) {
            this.secret = secret;
        }
    }

    public static class Send {
        private boolean viaServer = false;

        public boolean isViaServer() {
            return viaServer;
        }

        public void setViaServer(boolean viaServer) {
            this.viaServer = viaServer;
        }
    }

    public static class Client {
        private boolean directSendFallback = true;

        public boolean isDirectSendFallback() {
            return directSendFallback;
        }

        public void setDirectSendFallback(boolean directSendFallback) {
            this.directSendFallback = directSendFallback;
        }
    }
}
