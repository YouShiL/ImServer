package com.hailiao.common.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 音频消息 DTO。
 */
@Schema(description = "音频消息信息")
public class AudioMessageDTO {

    @Schema(description = "音频地址", example = "/uploads/audios/1/2026/03/12/voice.mp3")
    private String url;

    @Schema(description = "音频时长（秒）", example = "30")
    private Integer duration;

    @Schema(description = "文件大小（字节）", example = "512000")
    private Long fileSize;

    @Schema(description = "音频格式", example = "mp3")
    private String format;

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public Integer getDuration() {
        return duration;
    }

    public void setDuration(Integer duration) {
        this.duration = duration;
    }

    public Long getFileSize() {
        return fileSize;
    }

    public void setFileSize(Long fileSize) {
        this.fileSize = fileSize;
    }

    public String getFormat() {
        return format;
    }

    public void setFormat(String format) {
        this.format = format;
    }
}
