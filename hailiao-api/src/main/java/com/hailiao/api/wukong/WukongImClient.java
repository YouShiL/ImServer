package com.hailiao.api.wukong;

/**
 * WuKongIM 服务端 HTTP 客户端（Phase 1 骨架）。
 * 禁止在 {@code MessageService} 等主流程中注入使用，直至 Phase 2 开关打开。
 */
public interface WukongImClient {

    WukongSendResult sendPrivateMessage(WukongPrivateSendRequest request);

    WukongSendResult sendGroupMessage(WukongGroupSendRequest request);
}
