package com.hailiao.api.wukong;

import com.hailiao.api.config.ImProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 向 WuKong Manager 注册连接凭据：{@code POST {apiBaseUrl}/user/token}。
 * <p>须与 Flutter SDK 传入的 uid、token、device_flag 一致，否则 TCP 握手会出现 device token not found。</p>
 */
@Service
public class WukongUserTokenSyncService {

    private static final Logger log = LoggerFactory.getLogger(WukongUserTokenSyncService.class);

    private final ImProperties imProperties;
    private final RestTemplate restTemplate;

    public WukongUserTokenSyncService(ImProperties imProperties, RestTemplateBuilder restTemplateBuilder) {
        this.imProperties = imProperties;
        this.restTemplate = restTemplateBuilder
                .setConnectTimeout(Duration.ofSeconds(3))
                .setReadTimeout(Duration.ofSeconds(8))
                .build();
    }

    /**
     * WuKong 在 TCP 握手时用 (uid, device_flag) 查已注册的 token。
     * hailiao_flutter 使用 {@code Options.newDefault(...)}，未设置 {@code deviceFlag}，SDK 默认为 0（日志里为 APP）。
     * 不可按业务 {@code deviceType} 映射为 2（桌面）：否则服务端注册了 flag=2，客户端仍以 0 连接 → device token not found。
     */
    public static int imClientDeviceFlag() {
        return 0;
    }

    public void syncUserTokenIfConfigured(String uid, String token, int deviceFlag) {
        ImProperties.Wukong wk = imProperties.getWukong();
        if (!wk.isSyncUserTokenOnAuth()) {
            return;
        }
        String base = wk.getApiBaseUrl();
        if (base == null || base.trim().isEmpty()) {
            return;
        }
        if (uid == null || uid.trim().isEmpty() || token == null || token.trim().isEmpty()) {
            return;
        }

        String url = base.trim().replaceAll("/+$", "") + "/user/token";

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("uid", uid.trim());
        body.put("token", token.trim());
        body.put("device_flag", deviceFlag);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

        try {
            ResponseEntity<String> resp = restTemplate.postForEntity(url, entity, String.class);
            if (resp.getStatusCode().is2xxSuccessful()) {
                log.debug("[wukong] user/token registered for uid={}", uid);
            } else {
                log.warn("[wukong] user/token unexpected status {} for uid={}", resp.getStatusCode(), uid);
            }
        } catch (RestClientException e) {
            log.warn("[wukong] user/token sync failed for uid={}: {}", uid, e.getMessage());
        }
    }
}
