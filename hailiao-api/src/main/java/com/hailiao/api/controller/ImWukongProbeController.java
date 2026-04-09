package com.hailiao.api.controller;

import com.hailiao.api.config.ImProperties;
import com.hailiao.api.wukong.WukongImClient;
import com.hailiao.api.wukong.WukongPrivateSendRequest;
import com.hailiao.api.wukong.WukongSendResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 本地/联调用连通性探测（不承载业务）。
 * <p>路径在 {@code /api/public/**}，免 JWT。</p>
 * <ul>
 *   <li>{@code im.wukong.enabled=false}：仅返回配置说明</li>
 *   <li>{@code im.wukong.enabled=true}：校验 {@link WukongImClient} Bean，并对 {@code apiBaseUrl/health} 发 GET（404 仍可说明网络已打到对端）</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/public/im")
public class ImWukongProbeController {

    private final ImProperties imProperties;

    @Autowired(required = false)
    private WukongImClient wukongImClient;

    @Autowired(required = false)
    @Qualifier("wukongImRestTemplate")
    private RestTemplate wukongImRestTemplate;

    public ImWukongProbeController(ImProperties imProperties) {
        this.imProperties = imProperties;
    }

    @GetMapping("/wukong-probe")
    public Map<String, Object> wukongProbe() {
        Map<String, Object> out = new LinkedHashMap<>();
        ImProperties.Wukong wk = imProperties.getWukong();
        out.put("im.wukong.enabled", wk.isEnabled());
        out.put("im.wukong.api-base-url", wk.getApiBaseUrl());

        if (!wk.isEnabled()) {
            out.put("message", "若需探测后端→WuKong：在 application.yml 设 im.wukong.enabled=true 并重启，再访问本 URL");
            return out;
        }

        if (wukongImClient == null) {
            out.put("wukongImClientBean", "MISSING — 检查 @ConditionalOnProperty 与配置");
            return out;
        }
        out.put("wukongImClientBean", "OK");

        if (wukongImRestTemplate == null) {
            out.put("wukongImRestTemplateBean", "MISSING");
            return out;
        }
        out.put("wukongImRestTemplateBean", "OK");

        String base = wk.getApiBaseUrl() == null ? "" : wk.getApiBaseUrl().trim().replaceAll("/+$", "");
        String healthUrl = base + "/health";
        out.put("healthGetUrl", healthUrl);

        try {
            ResponseEntity<String> resp = wukongImRestTemplate.getForEntity(healthUrl, String.class);
            int code = resp.getStatusCodeValue();
            out.put("healthHttpStatus", code);
            out.put("networkOk", true);
            out.put("note", "2xx 表示 WuKong health 正常；404 仅表示路径不对，但 TCP 已到对端；连接拒绝为网络/地址错误");
            out.put("bodyPreview", abbreviate(resp.getBody(), 256));
        } catch (Exception ex) {
            out.put("networkOk", false);
            out.put("healthError", ex.getMessage());
            out.put("healthErrorType", ex.getClass().getSimpleName());
        }

        // 占位 send（会打 [im.send]，并尝试 POST 占位路径；失败不影响上面 health 结论）
        try {
            WukongPrivateSendRequest req = new WukongPrivateSendRequest();
            req.setFromUid("probe");
            req.setToUid("probe");
            req.setPayload("__connectivity_probe__");
            WukongSendResult sendResult = wukongImClient.sendPrivateMessage(req);
            out.put("skeletonSendPrivateSuccess", sendResult.isSuccess());
            out.put("skeletonSendPrivateDetail", sendResult.getDetail());
        } catch (Exception ex) {
            out.put("skeletonSendPrivateException", ex.getMessage());
        }

        return out;
    }

    private static String abbreviate(String s, int max) {
        if (s == null) {
            return "";
        }
        return s.length() <= max ? s : s.substring(0, max) + "...";
    }
}
