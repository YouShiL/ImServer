package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 发送私聊消息请求DTO
 *
 * @author 嗨聊开发团队
 * @version 1.0.0
 */
@Schema(description = "发送私聊消息请求DTO")
public class SendPrivateMessageRequestDTO {

    @Schema(description = "接收消息的用户ID", required = true, example = "2")
    private Long toUserId;

    @Schema(description = "消息内容", required = true, example = "你好，这是一条测试消息")
    private String content;

    @Schema(description = "消息类型，1-文本，2-图片，3-音频，4-视频", required = false, example = "1")
    private Integer msgType;

    @Schema(description = "消息附加信息，如图片URL、音频时长等", required = false, example = "{\"url\": \"https://example.com/image.jpg\"}")
    private String extra;

    public Long getToUserId() { return toUserId; }
    public void setToUserId(Long toUserId) { this.toUserId = toUserId; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public Integer getMsgType() { return msgType; }
    public void setMsgType(Integer msgType) { this.msgType = msgType; }
    public String getExtra() { return extra; }
    public void setExtra(String extra) { this.extra = extra; }
}