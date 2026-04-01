package com.hailiao.common.service;

import com.hailiao.common.config.FileUploadConfig;
import com.hailiao.common.dto.FileUploadResultDTO;
import com.hailiao.common.entity.ContentAudit;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.io.IOException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FileUploadServiceTest {

    @Mock
    private OssStorageService ossStorageService;

    @Mock
    private ContentAuditService contentAuditService;

    @InjectMocks
    private FileUploadService fileUploadService;

    private FileUploadConfig config;

    @BeforeEach
    void setUp() {
        config = new FileUploadConfig();
        config.setMaxFileSize(10 * 1024 * 1024L);
        config.setImageMaxSize(5 * 1024 * 1024L);
        config.setVideoMaxSize(100 * 1024 * 1024L);
        config.setAudioMaxSize(20 * 1024 * 1024L);
        setConfigField(config, "allowedImageTypes", "jpg,jpeg,png,gif,bmp,webp");
        setConfigField(config, "allowedVideoTypes", "mp4,avi,mov,wmv,flv,mkv");
        setConfigField(config, "allowedAudioTypes", "mp3,wav,aac,ogg,m4a");
        setConfig(fileUploadService, config);
    }

    @Test
    void uploadImageShouldRejectUnsupportedExtension() {
        MockMultipartFile file = new MockMultipartFile("file", "a.txt", "text/plain", new byte[]{1});

        IOException error = assertThrows(IOException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() throws Throwable {
                        fileUploadService.uploadImage(file, 1L);
                    }
                });

        assertEquals("不支持的图片格式，仅支持: jpg, jpeg, png, gif, bmp, webp", error.getMessage());
    }

    @Test
    void uploadVideoShouldRejectOversizedFile() {
        byte[] content = new byte[2];
        MockMultipartFile file = new MockMultipartFile("file", "a.mp4", "video/mp4", content) {
            @Override
            public long getSize() {
                return 101L * 1024 * 1024;
            }
        };

        IOException error = assertThrows(IOException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() throws Throwable {
                        fileUploadService.uploadVideo(file, 1L);
                    }
                });

        assertEquals("视频大小超过限制，最大允许: 100.00 MB", error.getMessage());
    }

    @Test
    void uploadAudioShouldCallStorageAndCreateAudit() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "a.mp3", "audio/mpeg", new byte[]{1, 2});
        FileUploadResultDTO result = new FileUploadResultDTO();
        result.setFileUrl("https://cdn/audio.mp3");
        result.setFilePath("audios/1/a.mp3");
        result.setOriginalFilename("a.mp3");
        result.setMimeType("audio/mpeg");
        result.setFileSize(2L);

        when(ossStorageService.upload(file, 1L, "audios")).thenReturn(result);

        FileUploadResultDTO saved = fileUploadService.uploadAudio(file, 1L);

        assertEquals("https://cdn/audio.mp3", saved.getFileUrl());
        verify(ossStorageService).upload(file, 1L, "audios");

        ArgumentCaptor<ContentAudit> captor = ArgumentCaptor.forClass(ContentAudit.class);
        verify(contentAuditService).createAudit(captor.capture());
        assertEquals(Integer.valueOf(3), captor.getValue().getContentType());
        assertEquals(Long.valueOf(1L), captor.getValue().getUserId());
    }

    @Test
    void uploadImageShouldSkipAuditWhenUserIdInvalid() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "a.jpg", "image/jpeg", new byte[]{1, 2});
        FileUploadResultDTO result = new FileUploadResultDTO();
        result.setFileUrl("https://cdn/image.jpg");

        when(ossStorageService.upload(file, 0L, "images")).thenReturn(result);

        fileUploadService.uploadImage(file, 0L);

        verify(contentAuditService, never()).createAudit(any(ContentAudit.class));
    }

    private void setConfig(FileUploadService service, FileUploadConfig fileUploadConfig) {
        try {
            java.lang.reflect.Field field = FileUploadService.class.getDeclaredField("config");
            field.setAccessible(true);
            field.set(service, fileUploadConfig);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private void setConfigField(FileUploadConfig fileUploadConfig, String fieldName, String value) {
        try {
            java.lang.reflect.Field field = FileUploadConfig.class.getDeclaredField(fieldName);
            field.setAccessible(true);
            field.set(fileUploadConfig, value);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
