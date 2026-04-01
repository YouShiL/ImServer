package com.hailiao.common.service;

import com.hailiao.common.config.FileUploadConfig;
import com.hailiao.common.dto.FileUploadResultDTO;
import com.hailiao.common.entity.ContentAudit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 文件上传服务。
 */
@Service
public class FileUploadService {

    private static final Logger logger = LoggerFactory.getLogger(FileUploadService.class);
    private static final int CONTENT_TYPE_IMAGE = 2;
    private static final int CONTENT_TYPE_AUDIO = 3;
    private static final int CONTENT_TYPE_VIDEO = 4;

    @Autowired
    private FileUploadConfig config;

    @Autowired
    private OssStorageService ossStorageService;

    @Autowired(required = false)
    private ContentAuditService contentAuditService;

    private static final Map<String, String> MIME_TYPE_MAP = new HashMap<>();

    static {
        MIME_TYPE_MAP.put("jpg", "image/jpeg");
        MIME_TYPE_MAP.put("jpeg", "image/jpeg");
        MIME_TYPE_MAP.put("png", "image/png");
        MIME_TYPE_MAP.put("gif", "image/gif");
        MIME_TYPE_MAP.put("bmp", "image/bmp");
        MIME_TYPE_MAP.put("webp", "image/webp");
        MIME_TYPE_MAP.put("mp4", "video/mp4");
        MIME_TYPE_MAP.put("avi", "video/x-msvideo");
        MIME_TYPE_MAP.put("mov", "video/quicktime");
        MIME_TYPE_MAP.put("wmv", "video/x-ms-wmv");
        MIME_TYPE_MAP.put("flv", "video/x-flv");
        MIME_TYPE_MAP.put("mkv", "video/x-matroska");
        MIME_TYPE_MAP.put("mp3", "audio/mpeg");
        MIME_TYPE_MAP.put("wav", "audio/wav");
        MIME_TYPE_MAP.put("aac", "audio/aac");
        MIME_TYPE_MAP.put("ogg", "audio/ogg");
        MIME_TYPE_MAP.put("m4a", "audio/mp4");
    }

    /**
     * 上传图片。
     */
    public FileUploadResultDTO uploadImage(MultipartFile file, Long userId) throws IOException {
        validateFile(file, "image");
        FileUploadResultDTO result = ossStorageService.upload(file, userId, "images");
        createUploadAuditIfNeeded(userId, result, CONTENT_TYPE_IMAGE);
        return result;
    }

    /**
     * 上传视频。
     */
    public FileUploadResultDTO uploadVideo(MultipartFile file, Long userId) throws IOException {
        validateFile(file, "video");
        FileUploadResultDTO result = ossStorageService.upload(file, userId, "videos");
        createUploadAuditIfNeeded(userId, result, CONTENT_TYPE_VIDEO);
        return result;
    }

    /**
     * 上传音频。
     */
    public FileUploadResultDTO uploadAudio(MultipartFile file, Long userId) throws IOException {
        validateFile(file, "audio");
        FileUploadResultDTO result = ossStorageService.upload(file, userId, "audios");
        createUploadAuditIfNeeded(userId, result, CONTENT_TYPE_AUDIO);
        return result;
    }

    private void createUploadAuditIfNeeded(Long userId, FileUploadResultDTO result, Integer contentType) {
        if (contentAuditService == null || userId == null || userId <= 0 || result == null || contentType == null) {
            return;
        }

        try {
            ContentAudit audit = new ContentAudit();
            audit.setContentType(contentType);
            audit.setUserId(userId);
            audit.setContent(buildUploadAuditContent(result));
            contentAuditService.createAudit(audit);
        } catch (Exception e) {
            logger.warn("\u521b\u5efa\u4e0a\u4f20\u5185\u5bb9\u5ba1\u6838\u8bb0\u5f55\u5931\u8d25: {}", e.getMessage());
        }
    }

    private String buildUploadAuditContent(FileUploadResultDTO result) {
        List<String> parts = new ArrayList<>();
        if (result.getFileUrl() != null && !result.getFileUrl().trim().isEmpty()) {
            parts.add("url=" + result.getFileUrl().trim());
        }
        if (result.getFilePath() != null && !result.getFilePath().trim().isEmpty()) {
            parts.add("path=" + result.getFilePath().trim());
        }
        if (result.getOriginalFilename() != null && !result.getOriginalFilename().trim().isEmpty()) {
            parts.add("name=" + result.getOriginalFilename().trim());
        }
        if (result.getMimeType() != null && !result.getMimeType().trim().isEmpty()) {
            parts.add("mime=" + result.getMimeType().trim());
        }
        if (result.getFileSize() != null) {
            parts.add("size=" + result.getFileSize());
        }
        return String.join("; ", parts);
    }

    /**
     * 校验文件格式和大小。
     */
    private void validateFile(MultipartFile file, String type) throws IOException {
        if (file.isEmpty()) {
            throw new IOException("\u6587\u4ef6\u4e0d\u80fd\u4e3a\u7a7a");
        }

        String extension = getFileExtension(file.getOriginalFilename()).toLowerCase();
        long fileSize = file.getSize();

        switch (type) {
            case "image":
                if (!Arrays.asList(config.getAllowedImageTypes()).contains(extension)) {
                    throw new IOException("\u4e0d\u652f\u6301\u7684\u56fe\u7247\u683c\u5f0f\uff0c\u4ec5\u652f\u6301: "
                            + String.join(", ", config.getAllowedImageTypes()));
                }
                if (fileSize > config.getImageMaxSize()) {
                    throw new IOException("\u56fe\u7247\u5927\u5c0f\u8d85\u8fc7\u9650\u5236\uff0c\u6700\u5927\u5141\u8bb8: "
                            + formatFileSize(config.getImageMaxSize()));
                }
                break;
            case "video":
                if (!Arrays.asList(config.getAllowedVideoTypes()).contains(extension)) {
                    throw new IOException("\u4e0d\u652f\u6301\u7684\u89c6\u9891\u683c\u5f0f\uff0c\u4ec5\u652f\u6301: "
                            + String.join(", ", config.getAllowedVideoTypes()));
                }
                if (fileSize > config.getVideoMaxSize()) {
                    throw new IOException("\u89c6\u9891\u5927\u5c0f\u8d85\u8fc7\u9650\u5236\uff0c\u6700\u5927\u5141\u8bb8: "
                            + formatFileSize(config.getVideoMaxSize()));
                }
                break;
            case "audio":
                if (!Arrays.asList(config.getAllowedAudioTypes()).contains(extension)) {
                    throw new IOException("\u4e0d\u652f\u6301\u7684\u97f3\u9891\u683c\u5f0f\uff0c\u4ec5\u652f\u6301: "
                            + String.join(", ", config.getAllowedAudioTypes()));
                }
                if (fileSize > config.getAudioMaxSize()) {
                    throw new IOException("\u97f3\u9891\u5927\u5c0f\u8d85\u8fc7\u9650\u5236\uff0c\u6700\u5927\u5141\u8bb8: "
                            + formatFileSize(config.getAudioMaxSize()));
                }
                break;
            default:
                if (fileSize > config.getMaxFileSize()) {
                    throw new IOException("\u6587\u4ef6\u5927\u5c0f\u8d85\u8fc7\u9650\u5236\uff0c\u6700\u5927\u5141\u8bb8: "
                            + formatFileSize(config.getMaxFileSize()));
                }
                break;
        }
    }

    /**
     * 获取文件扩展名。
     */
    private String getFileExtension(String filename) {
        if (filename == null || filename.lastIndexOf(".") == -1) {
            return "";
        }
        return filename.substring(filename.lastIndexOf(".") + 1);
    }

    /**
     * 格式化文件大小。
     */
    private String formatFileSize(long size) {
        if (size < 1024) {
            return size + " B";
        } else if (size < 1024 * 1024) {
            return String.format("%.2f KB", size / 1024.0);
        } else if (size < 1024 * 1024 * 1024) {
            return String.format("%.2f MB", size / (1024.0 * 1024));
        } else {
            return String.format("%.2f GB", size / (1024.0 * 1024 * 1024));
        }
    }

    /**
     * 删除文件。
     */
    public boolean deleteFile(String filePath) {
        return ossStorageService.delete(filePath);
    }
}
