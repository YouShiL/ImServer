package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.Date;

@Schema(description = "会话DTO - 会话详细信息")
public class ConversationDTO {

    @Schema(description = "会话ID", type = "Long", example = "1", title = "会话唯一标识")
    private Long id;

    @Schema(description = "用户ID", type = "Long", example = "1", title = "所属用户的ID")
    private Long userId;

    @Schema(description = "目标ID", type = "Long", example = "2", title = "会话对方用户ID或群组ID")
    private Long targetId;

    @Schema(description = "会话类型", type = "Integer", example = "1", title = "会话类型：1-私聊 2-群聊")
    private Integer type;

    @Schema(description = "会话名称", type = "String", example = "好友昵称或群名", title = "会话显示名称")
    private String name;

    @Schema(description = "会话头像", type = "String", example = "https://example.com/avatar.jpg", title = "会话对方头像或群头像")
    private String avatar;

    @Schema(description = "最后一条消息内容", type = "String", example = "你好", title = "会话中最后一条消息的内容")
    private String lastMessage;

    @Schema(description = "最后一条消息时间", type = "Date", example = "2026-03-12T10:00:00", title = "最后一条消息的发送时间")
    private Date lastMessageTime;

    @Schema(description = "未读消息数量", type = "Integer", example = "5", title = "未读取的消息数量")
    private Integer unreadCount;

    @Schema(description = "是否置顶", type = "Boolean", example = "false", title = "是否置顶会话")
    private Boolean isTop;

    @Schema(description = "是否静音", type = "Boolean", example = "false", title = "是否静音该会话")
    private Boolean isMute;

    @Schema(description = "草稿内容", type = "String", example = "未发送的草稿内容", title = "未发送的草稿消息内容")
    private String draft;

    @Schema(description = "是否删除", type = "Boolean", example = "false", title = "是否已删除会话")
    private Boolean isDeleted;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getTargetId() { return targetId; }
    public void setTargetId(Long targetId) { this.targetId = targetId; }

    public Integer getType() { return type; }
    public void setType(Integer type) { this.type = type; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getAvatar() { return avatar; }
    public void setAvatar(String avatar) { this.avatar = avatar; }

    public String getLastMessage() { return lastMessage; }
    public void setLastMessage(String lastMessage) { this.lastMessage = lastMessage; }

    public Date getLastMessageTime() { return lastMessageTime; }
    public void setLastMessageTime(Date lastMessageTime) { this.lastMessageTime = lastMessageTime; }

    public Integer getUnreadCount() { return unreadCount; }
    public void setUnreadCount(Integer unreadCount) { this.unreadCount = unreadCount; }

    public Boolean getIsTop() { return isTop; }
    public void setIsTop(Boolean isTop) { this.isTop = isTop; }

    public Boolean getIsMute() { return isMute; }
    public void setIsMute(Boolean isMute) { this.isMute = isMute; }

    public String getDraft() { return draft; }
    public void setDraft(String draft) { this.draft = draft; }

    public Boolean getIsDeleted() { return isDeleted; }
    public void setIsDeleted(Boolean isDeleted) { this.isDeleted = isDeleted; }
}
