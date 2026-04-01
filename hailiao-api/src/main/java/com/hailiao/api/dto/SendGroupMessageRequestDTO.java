package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 发送群聊消息请求DTO
 *
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Schema(description = "发送群聊消息请求DTO")
public class SendGroupMessageRequestDTO {

    @Schema(description = "群组ID", required = true, example = "1")
    private Long groupId;

    @Schema(description = "消息内容", required = true, example = "大家好，这是一条群聊测试消息")
    private String content;

    @Schema(description = "消息类型，1-文本，2-图片，3-音频，4-视频", required = false, example = "1")
    private Integer msgType;

    @Schema(description = "消息附加信息，如图片URL、音频时长等", required = false, example = "{\"url\": \"https://example.com/image.jpg\"}")
    private String extra;

    public Long getGroupId() { return groupId; }
    public void setGroupId(Long groupId) { this.groupId = groupId; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public Integer getMsgType() { return msgType; }
    public void setMsgType(Integer msgType) { this.msgType = msgType; }
    public String getExtra() { return extra; }
    public void setExtra(String extra) { this.extra = extra; }
}