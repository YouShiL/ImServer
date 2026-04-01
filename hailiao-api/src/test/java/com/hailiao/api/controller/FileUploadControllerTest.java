package com.hailiao.api.controller;

import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.dto.FileUploadResultDTO;
import com.hailiao.common.service.FileUploadService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;

import java.io.IOException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FileUploadControllerTest {

    @Mock
    private FileUploadService fileUploadService;

    @InjectMocks
    private FileUploadController fileUploadController;

    @Test
    void uploadImageShouldReturnUploadResult() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "a.jpg", "image/jpeg", new byte[]{1, 2});
        FileUploadResultDTO result = buildResult("https://cdn/image.jpg");

        when(fileUploadService.uploadImage(file, 1L)).thenReturn(result);

        ResponseEntity<ResponseDTO<FileUploadResultDTO>> response = fileUploadController.uploadImage(1L, file);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("https://cdn/image.jpg", response.getBody().getData().getFileUrl());
    }

    @Test
    void uploadVideoShouldReturnBadRequestWhenServiceThrows() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "a.mp4", "video/mp4", new byte[]{1, 2});
        when(fileUploadService.uploadVideo(file, 1L)).thenThrow(new IOException("上传失败"));

        ResponseEntity<ResponseDTO<FileUploadResultDTO>> response = fileUploadController.uploadVideo(1L, file);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(400, response.getBody().getCode());
    }

    @Test
    void uploadAudioShouldDelegateToService() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "a.mp3", "audio/mpeg", new byte[]{1, 2});
        FileUploadResultDTO result = buildResult("https://cdn/audio.mp3");
        when(fileUploadService.uploadAudio(file, 1L)).thenReturn(result);

        ResponseEntity<ResponseDTO<FileUploadResultDTO>> response = fileUploadController.uploadAudio(1L, file);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(fileUploadService).uploadAudio(file, 1L);
    }

    private FileUploadResultDTO buildResult(String url) {
        FileUploadResultDTO result = new FileUploadResultDTO();
        result.setFileUrl(url);
        result.setFilename("file-1");
        return result;
    }
}
