package com.hailiao.common.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

/**
 * 文件上传配置。
 */
@Configuration
public class FileUploadConfig {

    @Value("${file.upload.path:./uploads}")
    private String uploadPath;

    @Value("${file.upload.max-size:10485760}")
    private long maxFileSize;

    @Value("${file.upload.image-max-size:5242880}")
    private long imageMaxSize;

    @Value("${file.upload.video-max-size:104857600}")
    private long videoMaxSize;

    @Value("${file.upload.audio-max-size:20971520}")
    private long audioMaxSize;

    @Value("${file.upload.allowed-image-types:jpg,jpeg,png,gif,bmp,webp}")
    private String allowedImageTypes;

    @Value("${file.upload.allowed-video-types:mp4,avi,mov,wmv,flv,mkv}")
    private String allowedVideoTypes;

    @Value("${file.upload.allowed-audio-types:mp3,wav,aac,ogg,m4a}")
    private String allowedAudioTypes;

    public String getUploadPath() {
        return uploadPath;
    }

    public void setUploadPath(String uploadPath) {
        this.uploadPath = uploadPath;
    }

    public long getMaxFileSize() {
        return maxFileSize;
    }

    public void setMaxFileSize(long maxFileSize) {
        this.maxFileSize = maxFileSize;
    }

    public long getImageMaxSize() {
        return imageMaxSize;
    }

    public void setImageMaxSize(long imageMaxSize) {
        this.imageMaxSize = imageMaxSize;
    }

    public long getVideoMaxSize() {
        return videoMaxSize;
    }

    public void setVideoMaxSize(long videoMaxSize) {
        this.videoMaxSize = videoMaxSize;
    }

    public long getAudioMaxSize() {
        return audioMaxSize;
    }

    public void setAudioMaxSize(long audioMaxSize) {
        this.audioMaxSize = audioMaxSize;
    }

    public String[] getAllowedImageTypes() {
        return allowedImageTypes.split(",");
    }

    public String[] getAllowedVideoTypes() {
        return allowedVideoTypes.split(",");
    }

    public String[] getAllowedAudioTypes() {
        return allowedAudioTypes.split(",");
    }
}
