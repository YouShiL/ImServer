package com.hailiao.api.controller;

import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.dto.FileUploadResultDTO;
import com.hailiao.common.service.FileUploadService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@Tag(name = "文件上传", description = "图片、视频、音频等文件上传接口")
@RestController
@RequestMapping("/api/upload")
public class FileUploadController {

    @Autowired
    private FileUploadService fileUploadService;

    @Operation(summary = "上传图片", description = "支持 jpg/jpeg/png/gif/bmp/webp，最大 5MB")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "上传成功"),
            @ApiResponse(responseCode = "400", description = "上传失败，文件格式不支持或大小超限"),
            @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PostMapping("/image")
    public ResponseEntity<ResponseDTO<FileUploadResultDTO>> uploadImage(
            @RequestAttribute("userId") Long userId,
            @Parameter(name = "file", description = "图片文件", required = true) @RequestParam("file") MultipartFile file) {
        try {
            FileUploadResultDTO result = fileUploadService.uploadImage(file, userId);
            return ResponseEntity.ok(ResponseDTO.success(result));
        } catch (IOException e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "上传视频", description = "支持 mp4/avi/mov/wmv/flv/mkv，最大 100MB")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "上传成功"),
            @ApiResponse(responseCode = "400", description = "上传失败，文件格式不支持或大小超限"),
            @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PostMapping("/video")
    public ResponseEntity<ResponseDTO<FileUploadResultDTO>> uploadVideo(
            @RequestAttribute("userId") Long userId,
            @Parameter(name = "file", description = "视频文件", required = true) @RequestParam("file") MultipartFile file) {
        try {
            FileUploadResultDTO result = fileUploadService.uploadVideo(file, userId);
            return ResponseEntity.ok(ResponseDTO.success(result));
        } catch (IOException e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "上传音频", description = "支持 mp3/wav/aac/ogg/m4a，最大 10MB")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "上传成功"),
            @ApiResponse(responseCode = "400", description = "上传失败，文件格式不支持或大小超限"),
            @ApiResponse(responseCode = "401", description = "未授权")
    })
    @PostMapping("/audio")
    public ResponseEntity<ResponseDTO<FileUploadResultDTO>> uploadAudio(
            @RequestAttribute("userId") Long userId,
            @Parameter(name = "file", description = "音频文件", required = true) @RequestParam("file") MultipartFile file) {
        try {
            FileUploadResultDTO result = fileUploadService.uploadAudio(file, userId);
            return ResponseEntity.ok(ResponseDTO.success(result));
        } catch (IOException e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }
}
