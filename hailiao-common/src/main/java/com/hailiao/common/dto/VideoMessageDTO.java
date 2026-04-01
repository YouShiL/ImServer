package com.hailiao.common.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 视频消息 DTO。
 */
@Schema(description = "视频消息信息")
public class VideoMessageDTO {

    @Schema(description = "视频地址", example = "/uploads/videos/1/2026/03/12/video.mp4")
    private String url;

    @Schema(description = "视频封面地址", example = "/uploads/videos/1/2026/03/12/video_cover.jpg")
    private String coverUrl;

    @Schema(description = "视频宽度（像素）", example = "1920")
    private Integer width;

    @Schema(description = "视频高度（像素）", example = "1080")
    private Integer height;

    @Schema(description = "视频时长（秒）", example = "120")
    private Integer duration;

    @Schema(description = "文件大小（字节）", example = "52428800")
    private Long fileSize;

    @Schema(description = "视频格式", example = "mp4")
    private String format;

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getCoverUrl() {
        return coverUrl;
    }

    public void setCoverUrl(String coverUrl) {
        this.coverUrl = coverUrl;
    }

    public Integer getWidth() {
        return width;
    }

    public void setWidth(Integer width) {
        this.width = width;
    }

    public Integer getHeight() {
        return height;
    }

    public void setHeight(Integer height) {
        this.height = height;
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
