package com.hailiao.common.im;

import com.hailiao.common.entity.Message;

/**
 * 业务消息落库后、对 WuKongIM 的出站调用（由 hailiao-api 实现；common 仅声明 SPI）。
 */
public interface WukongOutboundBridge {

    void afterPrivateMessageSaved(Message message, String clientMsgNo);

    void afterGroupMessageSaved(Message message, String clientMsgNo);
}
