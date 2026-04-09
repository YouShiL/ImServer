package com.hailiao.api.controller;

import com.hailiao.api.config.ImProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.util.StreamUtils;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

/**
 * WuKongIM Webhook 接收骨架（Phase 1）：只打日志，不做业务入库。
 * <p>路径默认 {@code /api/im/webhook}，可通过 {@code im.webhook.path} 覆盖。</p>
 */
@RestController
public class ImWebhookController {

    private static final Logger log = LoggerFactory.getLogger(ImWebhookController.class);

    private final ImProperties imProperties;

    public ImWebhookController(ImProperties imProperties) {
        this.imProperties = imProperties;
    }

    /**
     * 使用配置的路径注册与 {@link org.springframework.web.servlet.handler.AbstractHandlerMethodMapping}
     * 兼容：path 不含尾部通配。
     */
    @RequestMapping(
            value = "${im.webhook.path:/api/im/webhook}",
            method = RequestMethod.POST,
            consumes = MediaType.ALL_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public Map<String, Object> receive(HttpServletRequest request) {
        String rawBody = "";
        try {
            rawBody = StreamUtils.copyToString(request.getInputStream(), StandardCharsets.UTF_8);
        } catch (Exception e) {
            log.warn("[im.webhook] read body failed: {}", e.toString());
        }

        String secret = imProperties.getWebhook().getSecret();
        if (secret == null || secret.trim().isEmpty()) {
            log.warn("[im.webhook] im.webhook.secret is empty; skipping signature verification (configure for production)");
        } else {
            // TODO: 按 WuKongIM 文档校验收件签名（请求头名称待确认）
            String sig = firstHeader(request,
                    "X-Wukong-Signature",
                    "X-WuKong-Signature",
                    "X-Signature",
                    "X-Request-Signature");
            log.debug("[im.webhook] signature header (not verified in skeleton): {}", sig);
        }

        Map<String, String> headerSnap = snapshotHeaders(request);
        log.info("[im.webhook] received: len={}, headers={}", rawBody.length(), headerSnap);
        log.debug("[im.webhook] body preview: {}", abbreviate(rawBody, 512));

        Map<String, Object> ok = new HashMap<>();
        ok.put("ok", true);
        ok.put("received", true);
        return ok;
    }

    private static Map<String, String> snapshotHeaders(HttpServletRequest request) {
        Map<String, String> m = new HashMap<>();
        Enumeration<String> names = request.getHeaderNames();
        if (names == null) {
            return m;
        }
        Collections.list(names).forEach(n -> m.put(n, request.getHeader(n)));
        return m;
    }

    private static String firstHeader(HttpServletRequest request, String... names) {
        for (String n : names) {
            String v = request.getHeader(n);
            if (v != null && !v.isEmpty()) {
                return v;
            }
        }
        return null;
    }

    private static String abbreviate(String s, int max) {
        if (s == null) {
            return "";
        }
        if (s.length() <= max) {
            return s;
        }
        return s.substring(0, max) + "...";
    }
}
