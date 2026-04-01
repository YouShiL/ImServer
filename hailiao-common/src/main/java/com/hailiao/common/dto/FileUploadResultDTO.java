package com.hailiao.common.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.Date;

/**
 * 文件上传结果 DTO。
 */
@Schema(description = "文件上传结果")
public class FileUploadResultDTO {

    @Schema(description = "新文件名（UUID 格式）", example = "a1b2c3d4e5f6g7h8.jpg")
    private String filename;

    @Schema(description = "原始文件名", example = "photo.jpg")
    private String originalFilename;

    @Schema(description = "文件访问地址", example = "/uploads/images/1/2026/03/12/a1b2c3d4e5f6g7h8.jpg")
    private String fileUrl;

    @Schema(description = "图片预览地址", example = "/uploads/images/1/2026/03/12/a1b2c3d4e5f6g7h8.jpg?x-oss-process=image/resize,m_fixed,w_200,h_200")
    private String previewUrl;

    @Schema(description = "文件存储路径", example = "./uploads/images/1/2026/03/12/a1b2c3d4e5f6g7h8.jpg")
    private String filePath;

    @Schema(description = "文件大小（字节）", example = "1024000")
    private Long fileSize;

    @Schema(description = "文件 MIME 类型", example = "image/jpeg")
    private String mimeType;

    @Schema(description = "文件扩展名", example = "jpg")
    private String extension;

    @Schema(description = "上传时间", example = "2026-03-12T10:30:00")
    private Date uploadTime;

    public String getFilename() {
        return filename;
    }

    public void setFilename(String filename) {
        this.filename = filename;
    }

    public String getOriginalFilename() {
        return originalFilename;
    }

    public void setOriginalFilename(String originalFilename) {
        this.originalFilename = originalFilename;
    }

    public String getFileUrl() {
        return fileUrl;
    }

    public void setFileUrl(String fileUrl) {
        this.fileUrl = fileUrl;
    }

    public String getPreviewUrl() {
        return previewUrl;
    }

    public void setPreviewUrl(String previewUrl) {
        this.previewUrl = previewUrl;
    }

    public String getFilePath() {
        return filePath;
    }

    public void setFilePath(String filePath) {
        this.filePath = filePath;
    }

    public Long getFileSize() {
        return fileSize;
    }

    public void setFileSize(Long fileSize) {
        this.fileSize = fileSize;
    }

    public String getMimeType() {
        return mimeType;
    }

    public void setMimeType(String mimeType) {
        this.mimeType = mimeType;
    }

    public String getExtension() {
        return extension;
    }

    public void setExtension(String extension) {
        this.extension = extension;
    }

    public Date getUploadTime() {
        return uploadTime;
    }

    public void setUploadTime(Date uploadTime) {
        this.uploadTime = uploadTime;
    }
}
