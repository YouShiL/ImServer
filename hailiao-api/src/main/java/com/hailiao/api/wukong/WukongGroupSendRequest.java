package com.hailiao.api.wukong;

/**
 * 群聊下发 WuKongIM 的请求骨架（Phase 1）。
 */
public class WukongGroupSendRequest {

    private String fromUid;
    private String groupChannelId;
    private String payload;

    public String getFromUid() {
        return fromUid;
    }

    public void setFromUid(String fromUid) {
        this.fromUid = fromUid;
    }

    public String getGroupChannelId() {
        return groupChannelId;
    }

    public void setGroupChannelId(String groupChannelId) {
        this.groupChannelId = groupChannelId;
    }

    public String getPayload() {
        return payload;
    }

    public void setPayload(String payload) {
        this.payload = payload;
    }
}
