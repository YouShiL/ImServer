package com.hailiao.api.im;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hailiao.api.config.ImProperties;
import com.hailiao.api.wukong.WukongGroupSendRequest;
import com.hailiao.api.wukong.WukongImClient;
import com.hailiao.api.wukong.WukongPrivateSendRequest;
import com.hailiao.common.entity.Message;
import com.hailiao.common.im.WukongOutboundBridge;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.HashMap;
import java.util.Map;

/**
 * 在 {@code im.send.via-server=true} 且 {@code im.wukong.enabled=true} 时调用 {@link WukongImClient}；
 * 失败只打日志，不影响已落库事务。
 */
@Component
public class WukongOutboundBridgeImpl implements WukongOutboundBridge {

    private static final Logger log = LoggerFactory.getLogger(WukongOutboundBridgeImpl.class);

    private final ImProperties imProperties;
    private final ObjectMapper objectMapper;

    @Autowired(required = false)
    private WukongImClient wukongImClient;

    public WukongOutboundBridgeImpl(ImProperties imProperties, ObjectMapper objectMapper) {
        this.imProperties = imProperties;
        this.objectMapper = objectMapper;
    }

    @Override
    public void afterPrivateMessageSaved(Message message, String clientMsgNo) {
        String cm = StringUtils.hasText(clientMsgNo)
                ? clientMsgNo.trim()
                : (message.getClientMsgNo() != null ? message.getClientMsgNo().trim() : "");
        String cprev = imPreview(message.getContent(), 200);
        log.info(
                "[im.send] dispatch private message (bridge enter): fromUid={} toUid={} clientMsgNo={} dbMessageId={} content={}",
                message.getFromUserId(),
                message.getToUserId(),
                cm,
                message.getId(),
                cprev);
        if (!shouldDispatch()) {
            return;
        }
        try {
            WukongPrivateSendRequest req = new WukongPrivateSendRequest();
            req.setFromUid(String.valueOf(message.getFromUserId()));
            req.setToUid(message.getToUserId() != null ? String.valueOf(message.getToUserId()) : "");
            req.setPayload(buildPayloadJson(message, clientMsgNo));
            log.info(
                    "[im.send] dispatch private message (WuKong client invoke): fromUid={} toUid={} clientMsgNo={} payloadPreview={}",
                    req.getFromUid(),
                    req.getToUid(),
                    cm,
                    imPreview(req.getPayload(), 400));
            wukongImClient.sendPrivateMessage(req);
        } catch (Exception e) {
            log.warn("[im.send] wukong private dispatch failed (non-fatal): {}", e.getMessage());
        }
    }

    @Override
    public void afterGroupMessageSaved(Message message, String clientMsgNo) {
        if (!shouldDispatch()) {
            return;
        }
        try {
            WukongGroupSendRequest req = new WukongGroupSendRequest();
            req.setFromUid(String.valueOf(message.getFromUserId()));
            req.setGroupChannelId(message.getGroupId() != null ? String.valueOf(message.getGroupId()) : "");
            req.setPayload(buildPayloadJson(message, clientMsgNo));
            wukongImClient.sendGroupMessage(req);
        } catch (Exception e) {
            log.warn("[im.send] wukong group dispatch failed (non-fatal): {}", e.getMessage());
        }
    }

    private boolean shouldDispatch() {
        if (!imProperties.getSend().isViaServer()) {
            log.info("[im.send] wukong dispatch skipped: im.send.via-server=false");
            return false;
        }
        if (!imProperties.getWukong().isEnabled()) {
            log.info("[im.send] wukong dispatch skipped: im.wukong.enabled=false");
            return false;
        }
        if (wukongImClient == null) {
            log.warn("[im.send] wukong dispatch skipped: WukongImClient bean absent (set im.wukong.enabled=true)");
            return false;
        }
        return true;
    }

    private static String imPreview(String s, int max) {
        if (!StringUtils.hasText(s)) {
            return "";
        }
        String t = s.trim();
        if (t.length() <= max) {
            return t;
        }
        return t.substring(0, max) + "…";
    }

    private String buildPayloadJson(Message message, String clientMsgNo) throws Exception {
        Map<String, Object> m = new HashMap<>();
        m.put("messageId", message.getId());
        m.put("msgType", message.getMsgType());
        m.put("content", message.getContent());
        if (message.getClientMsgNo() != null && !message.getClientMsgNo().trim().isEmpty()) {
            m.put("clientMsgNo", message.getClientMsgNo().trim());
        } else if (clientMsgNo != null && !clientMsgNo.trim().isEmpty()) {
            m.put("clientMsgNo", clientMsgNo.trim());
        }
        return objectMapper.writeValueAsString(m);
    }
}
