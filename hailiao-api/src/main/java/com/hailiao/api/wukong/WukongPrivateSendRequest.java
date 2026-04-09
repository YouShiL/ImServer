package com.hailiao.api.wukong;

/**
 * 私聊下发 WuKongIM 的请求骨架（Phase 1，未接入真实 API 字段）。
 */
public class WukongPrivateSendRequest {

    private String fromUid;
    private String toUid;
    /** 业务层透传的文本或序列化后的 payload，具体格式以后按 WuKong 文档对齐 */
    private String payload;

    public String getFromUid() {
        return fromUid;
    }

    public void setFromUid(String fromUid) {
        this.fromUid = fromUid;
    }

    public String getToUid() {
        return toUid;
    }

    public void setToUid(String toUid) {
        this.toUid = toUid;
    }

    public String getPayload() {
        return payload;
    }

    public void setPayload(String payload) {
        this.payload = payload;
    }
}
