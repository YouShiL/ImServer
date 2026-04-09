package com.hailiao.api.config;

/**
 * Webhook 路径与 {@code HttpServletRequest#getRequestURI()} 对齐（去尾部斜杠、补前导 /）。
 */
public final class ImWebhookPaths {

    private ImWebhookPaths() {
    }

    public static String normalizedPath(ImProperties imProperties) {
        String p = imProperties.getWebhook().getPath();
        if (p == null || p.trim().isEmpty()) {
            return "/api/im/webhook";
        }
        p = p.trim();
        while (p.length() > 1 && p.endsWith("/")) {
            p = p.substring(0, p.length() - 1);
        }
        if (!p.startsWith("/")) {
            p = "/" + p;
        }
        return p;
    }

    public static boolean matchesRequestUri(ImProperties imProperties, String requestUri) {
        if (requestUri == null) {
            return false;
        }
        String p = normalizedPath(imProperties);
        String u = requestUri;
        while (u.length() > 1 && u.endsWith("/")) {
            u = u.substring(0, u.length() - 1);
        }
        return u.equals(p) || u.startsWith(p + "/");
    }
}
