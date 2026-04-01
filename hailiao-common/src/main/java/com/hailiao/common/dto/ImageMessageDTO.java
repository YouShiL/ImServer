package com.hailiao.common.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 图片消息 DTO。
 */
@Schema(description = "图片消息信息")
public class ImageMessageDTO {

    @Schema(description = "图片地址", example = "/uploads/images/1/2026/03/12/photo.jpg")
    private String url;

    @Schema(description = "缩略图地址", example = "/uploads/images/1/2026/03/12/photo_thumb.jpg")
    private String thumbUrl;

    @Schema(description = "图片宽度（像素）", example = "1920")
    private Integer width;

    @Schema(description = "图片高度（像素）", example = "1080")
    private Integer height;

    @Schema(description = "文件大小（字节）", example = "1024000")
    private Long fileSize;

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getThumbUrl() {
        return thumbUrl;
    }

    public void setThumbUrl(String thumbUrl) {
        this.thumbUrl = thumbUrl;
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

    public Long getFileSize() {
        return fileSize;
    }

    public void setFileSize(Long fileSize) {
        this.fileSize = fileSize;
    }
}
