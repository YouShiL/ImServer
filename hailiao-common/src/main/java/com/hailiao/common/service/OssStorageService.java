package com.hailiao.common.service;

import com.aliyun.oss.OSS;
import com.aliyun.oss.OSSClientBuilder;
import com.aliyun.oss.model.ObjectMetadata;
import com.aliyun.oss.model.PutObjectRequest;
import com.hailiao.common.config.OssConfig;
import com.hailiao.common.dto.FileUploadResultDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;
import java.util.UUID;

/**
 * 阿里云 OSS 存储服务。
 */
@Service
public class OssStorageService {

    @Autowired
    private OssConfig ossConfig;

    private OSS ossClient;

    /**
     * 获取 OSS 客户端。
     */
    private OSS getOssClient() {
        if (ossClient == null) {
            ossClient = new OSSClientBuilder().build(
                    ossConfig.getEndpoint(),
                    ossConfig.getAccessKeyId(),
                    ossConfig.getAccessKeySecret()
            );
        }
        return ossClient;
    }

    /**
     * 上传文件到 OSS。
     */
    public FileUploadResultDTO upload(MultipartFile file, Long userId, String category) throws IOException {
        String originalFilename = file.getOriginalFilename();
        String extension = getFileExtension(originalFilename);
        String newFilename = UUID.randomUUID().toString().replace("-", "") + "." + extension;

        String datePath = new SimpleDateFormat("yyyy/MM/dd").format(new Date());
        String objectKey = ossConfig.getPrefix() + "/" + category + "/" + userId + "/" + datePath + "/" + newFilename;

        if ("your-access-key-id".equals(ossConfig.getAccessKeyId())) {
            String fileUrl = ossConfig.getDomain() + "/" + objectKey;
            String previewUrl = isImage(extension) ? generatePreviewUrl(objectKey) : null;
            FileUploadResultDTO result = new FileUploadResultDTO();
            result.setFilename(newFilename);
            result.setOriginalFilename(originalFilename);
            result.setFileUrl(fileUrl);
            result.setPreviewUrl(previewUrl);
            result.setFilePath(objectKey);
            result.setFileSize(file.getSize());
            result.setMimeType(getContentType(extension));
            result.setExtension(extension);
            result.setUploadTime(new Date());
            return result;
        }

        try (InputStream inputStream = file.getInputStream()) {
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(file.getSize());
            metadata.setContentType(getContentType(extension));

            PutObjectRequest request = new PutObjectRequest(
                    ossConfig.getBucketName(),
                    objectKey,
                    inputStream,
                    metadata
            );

            getOssClient().putObject(request);

            String fileUrl = ossConfig.getDomain() + "/" + objectKey;
            String previewUrl = isImage(extension) ? generatePreviewUrl(objectKey) : null;

            FileUploadResultDTO result = new FileUploadResultDTO();
            result.setFilename(newFilename);
            result.setOriginalFilename(originalFilename);
            result.setFileUrl(fileUrl);
            result.setPreviewUrl(previewUrl);
            result.setFilePath(objectKey);
            result.setFileSize(file.getSize());
            result.setMimeType(getContentType(extension));
            result.setExtension(extension);
            result.setUploadTime(new Date());
            return result;
        }
    }

    /**
     * 删除 OSS 文件。
     */
    public boolean delete(String objectKey) {
        try {
            getOssClient().deleteObject(ossConfig.getBucketName(), objectKey);
            return true;
        } catch (Exception e) {
            return false;
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
     * 获取 MIME 类型。
     */
    private String getContentType(String extension) {
        extension = extension.toLowerCase();
        switch (extension) {
            case "jpg":
            case "jpeg":
                return "image/jpeg";
            case "png":
                return "image/png";
            case "gif":
                return "image/gif";
            case "bmp":
                return "image/bmp";
            case "webp":
                return "image/webp";
            case "mp4":
                return "video/mp4";
            case "avi":
                return "video/x-msvideo";
            case "mov":
                return "video/quicktime";
            case "wmv":
                return "video/x-ms-wmv";
            case "flv":
                return "video/x-flv";
            case "mkv":
                return "video/x-matroska";
            case "mp3":
                return "audio/mpeg";
            case "wav":
                return "audio/wav";
            case "aac":
                return "audio/aac";
            case "ogg":
                return "audio/ogg";
            case "m4a":
                return "audio/mp4";
            default:
                return "application/octet-stream";
        }
    }

    /**
     * 关闭 OSS 客户端。
     */
    public void destroy() {
        if (ossClient != null) {
            ossClient.shutdown();
        }
    }

    /**
     * 判断是否为图片文件。
     */
    private boolean isImage(String extension) {
        extension = extension.toLowerCase();
        return Arrays.asList("jpg", "jpeg", "png", "gif", "bmp", "webp").contains(extension);
    }

    /**
     * 生成图片预览地址。
     */
    private String generatePreviewUrl(String objectKey) {
        return ossConfig.getDomain() + "/" + objectKey + "?x-oss-process=image/resize,m_fixed,w_200,h_200";
    }
}
