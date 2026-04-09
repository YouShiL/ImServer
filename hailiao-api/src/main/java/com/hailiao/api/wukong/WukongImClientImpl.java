package com.hailiao.api.wukong;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hailiao.api.config.ImProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * WuKongIM Manager：官方文档 {@code POST /message/send}，
 * 字段 snake_case，{@code payload} 为 inner 消息 JSON 的 Base64（UTF-8）。
 *
 * <p>私聊：{@code channel_type=1}，{@code channel_id} 为对方 uid；群聊：{@code channel_type=2}，{@code channel_id} 为群 id。
 */
@Component
@ConditionalOnProperty(name = "im.wukong.enabled", havingValue = "true")
public class WukongImClientImpl implements WukongImClient {

    private static final Logger log = LoggerFactory.getLogger(WukongImClientImpl.class);

    private static final String MESSAGE_SEND_PATH = "/message/send";

    private final ImProperties imProperties;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public WukongImClientImpl(
            ImProperties imProperties,
            @Qualifier("wukongImRestTemplate") RestTemplate wukongImRestTemplate,
            ObjectMapper objectMapper) {
        this.imProperties = imProperties;
        this.restTemplate = wukongImRestTemplate;
        this.objectMapper = objectMapper;
    }

    @Override
    public WukongSendResult sendPrivateMessage(WukongPrivateSendRequest request) {
        String payload = request.getPayload();
        log.info(
                "[im.send] dispatch private message (HTTP client): fromUid={} toUid={} payloadLen={} payloadPreview={}",
                request.getFromUid(),
                request.getToUid(),
                payload != null ? payload.length() : 0,
                preview(payload, 400));
        String url = normalizeBaseUrl(imProperties.getWukong().getApiBaseUrl()) + MESSAGE_SEND_PATH;
        Map<String, Object> body = buildMessageSendJson(
                request.getFromUid(),
                request.getToUid(),
                1,
                payload);
        postMessageSend(url, body);
        return WukongSendResult.ok("message_send");
    }

    @Override
    public WukongSendResult sendGroupMessage(WukongGroupSendRequest request) {
        String payload = request.getPayload();
        log.info(
                "[im.send] sendGroupMessage: fromUid={} groupChannelId={} payloadLen={}",
                request.getFromUid(),
                request.getGroupChannelId(),
                payload != null ? payload.length() : 0);
        String url = normalizeBaseUrl(imProperties.getWukong().getApiBaseUrl()) + MESSAGE_SEND_PATH;
        Map<String, Object> body = buildMessageSendJson(
                request.getFromUid(),
                request.getGroupChannelId(),
                2,
                payload);
        postMessageSend(url, body);
        return WukongSendResult.ok("message_send");
    }

    private Map<String, Object> buildMessageSendJson(
            String fromUid,
            String channelId,
            int channelType,
            String bridgePayloadJson) {
        try {
            String innerJson = buildInnerContentJson(bridgePayloadJson);
            String b64 = Base64.getEncoder().encodeToString(innerJson.getBytes(StandardCharsets.UTF_8));
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("from_uid", fromUid != null ? fromUid : "");
            body.put("channel_id", channelId != null ? channelId : "");
            body.put("channel_type", channelType);
            body.put("payload", b64);
            String cm = extractClientMsgNo(bridgePayloadJson);
            if (cm != null && !cm.trim().isEmpty()) {
                body.put("client_msg_no", cm.trim());
            }
            return body;
        } catch (Exception e) {
            throw new IllegalStateException("build WuKong message/send body failed", e);
        }
    }

    /**
     * 将业务层 JSON（含 msgType、content、clientMsgNo…）转为 WuKong inner：{@code {"type":int,"content":"..."}}。
     * 非 JSON 字符串整段视为文本 content（兼容 probe）。
     */
    private String buildInnerContentJson(String bridgePayloadJson) throws Exception {
        if (bridgePayloadJson == null || bridgePayloadJson.trim().isEmpty()) {
            return innerTypeContent(1, "", null);
        }
        try {
            JsonNode node = objectMapper.readTree(bridgePayloadJson);
            if (!node.isObject()) {
                return innerTypeContent(1, bridgePayloadJson, null);
            }
            int type = node.has("msgType") ? node.get("msgType").asInt(1) : 1;
            JsonNode c = node.get("content");
            String content = c != null && !c.isNull() ? c.asText("") : "";
            return innerTypeContent(type, content, node);
        } catch (Exception e) {
            return innerTypeContent(1, bridgePayloadJson, null);
        }
    }

    /**
     * Inner JSON 除 WuKong 必需的 type/content 外，附带业务 {@code messageId}（DB）、{@code clientMsgNo}，
     * 便于 Flutter 与 REST 历史去重（与 IM 的 messageID 区分）。
     */
    private String innerTypeContent(int type, String content, JsonNode businessSource)
            throws Exception {
        Map<String, Object> inner = new LinkedHashMap<>();
        inner.put("type", type);
        inner.put("content", content != null ? content : "");
        if (businessSource != null && businessSource.isObject()) {
            if (businessSource.has("messageId") && !businessSource.get("messageId").isNull()) {
                inner.put("messageId", businessSource.get("messageId").asLong());
            }
            if (businessSource.has("clientMsgNo") && !businessSource.get("clientMsgNo").isNull()) {
                String cm = businessSource.get("clientMsgNo").asText("");
                if (!cm.isEmpty()) {
                    inner.put("clientMsgNo", cm);
                }
            }
        }
        return objectMapper.writeValueAsString(inner);
    }

    private String extractClientMsgNo(String bridgePayloadJson) {
        if (bridgePayloadJson == null || bridgePayloadJson.trim().isEmpty()) {
            return "";
        }
        try {
            JsonNode node = objectMapper.readTree(bridgePayloadJson);
            if (node.has("clientMsgNo") && !node.get("clientMsgNo").isNull()) {
                return node.get("clientMsgNo").asText("");
            }
        } catch (Exception ignored) {
            // ignore
        }
        return "";
    }

    private void postMessageSend(String url, Map<String, Object> body) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));
            String token = imProperties.getWukong().getManagerToken();
            if (token != null && !token.trim().isEmpty()) {
                headers.setBearerAuth(token.trim());
            }
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
            ResponseEntity<String> resp = restTemplate.postForEntity(url, entity, String.class);
            String respBody = resp.getBody();
            String bodyPrev = respBody == null
                    ? ""
                    : (respBody.length() > 512 ? respBody.substring(0, 512) + "…" : respBody);
            if (resp.getStatusCode().is2xxSuccessful()) {
                log.info("[im.send] wukong HTTP POST url={} httpStatus={} responseBody={}", url, resp.getStatusCode(), bodyPrev);
            } else {
                log.warn(
                        "[im.send] wukong HTTP POST non-2xx url={} httpStatus={} responseBody={}",
                        url,
                        resp.getStatusCode(),
                        bodyPrev);
            }
        } catch (Exception ex) {
            log.warn("[im.send] wukong HTTP POST failed url={} — {}", url, ex.toString());
        }
    }

    private static String normalizeBaseUrl(String base) {
        if (base == null) {
            return "";
        }
        return base.trim().replaceAll("/+$", "");
    }

    private static String preview(String s, int max) {
        if (s == null || s.isEmpty()) {
            return "";
        }
        String t = s.trim();
        if (t.length() <= max) {
            return t;
        }
        return t.substring(0, max) + "…";
    }
}
