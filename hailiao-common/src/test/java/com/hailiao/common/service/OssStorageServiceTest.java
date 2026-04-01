package com.hailiao.common.service;

import com.hailiao.common.config.OssConfig;
import com.hailiao.common.dto.FileUploadResultDTO;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.io.IOException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OssStorageServiceTest {

    @Mock
    private OssConfig ossConfig;

    @InjectMocks
    private OssStorageService ossStorageService;

    @Test
    void uploadShouldReturnMockResultWhenUsingPlaceholderAccessKey() throws IOException {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "avatar.png",
                "image/png",
                "image-content".getBytes()
        );

        when(ossConfig.getAccessKeyId()).thenReturn("your-access-key-id");
        when(ossConfig.getDomain()).thenReturn("https://cdn.example.com");
        when(ossConfig.getPrefix()).thenReturn("hailiao");

        FileUploadResultDTO result = ossStorageService.upload(file, 1L, "image");

        assertNotNull(result.getFilename());
        assertEquals("avatar.png", result.getOriginalFilename());
        assertTrue(result.getFileUrl().startsWith("https://cdn.example.com/hailiao/image/1/"));
        assertTrue(result.getPreviewUrl().contains("x-oss-process=image/resize"));
        assertEquals(Long.valueOf(file.getSize()), result.getFileSize());
        assertEquals("image/png", result.getMimeType());
        assertEquals("png", result.getExtension());
        assertNotNull(result.getUploadTime());
    }

    @Test
    void uploadShouldUseOctetStreamForUnknownExtension() throws IOException {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "archive.bin",
                "application/octet-stream",
                "data".getBytes()
        );

        when(ossConfig.getAccessKeyId()).thenReturn("your-access-key-id");
        when(ossConfig.getDomain()).thenReturn("https://cdn.example.com");
        when(ossConfig.getPrefix()).thenReturn("hailiao");

        FileUploadResultDTO result = ossStorageService.upload(file, 2L, "file");

        assertEquals("application/octet-stream", result.getMimeType());
        assertEquals("bin", result.getExtension());
        assertNull(result.getPreviewUrl());
    }
}
