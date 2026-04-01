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

@Tag(name = "\u6587\u4ef6\u4e0a\u4f20", description = "\u56fe\u7247\u3001\u89c6\u9891\u3001\u97f3\u9891\u7b49\u6587\u4ef6\u4e0a\u4f20\u63a5\u53e3")
@RestController
@RequestMapping("/api/upload")
public class FileUploadController {

    @Autowired
    private FileUploadService fileUploadService;

    @Operation(summary = "\u4e0a\u4f20\u56fe\u7247", description = "\u652f\u6301 jpg/jpeg/png/gif/bmp/webp\uff0c\u6700\u5927 5MB")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "\u4e0a\u4f20\u6210\u529f"),
            @ApiResponse(responseCode = "400", description = "\u4e0a\u4f20\u5931\u8d25\uff0c\u6587\u4ef6\u683c\u5f0f\u4e0d\u652f\u6301\u6216\u5927\u5c0f\u8d85\u9650"),
            @ApiResponse(responseCode = "401", description = "\u672a\u6388\u6743")
    })
    @PostMapping("/image")
    public ResponseEntity<ResponseDTO<FileUploadResultDTO>> uploadImage(
            @RequestAttribute("userId") Long userId,
            @Parameter(name = "file", description = "\u56fe\u7247\u6587\u4ef6", required = true) @RequestParam("file") MultipartFile file) {
        try {
            FileUploadResultDTO result = fileUploadService.uploadImage(file, userId);
            return ResponseEntity.ok(ResponseDTO.success(result));
        } catch (IOException e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "\u4e0a\u4f20\u89c6\u9891", description = "\u652f\u6301 mp4/avi/mov/wmv/flv/mkv\uff0c\u6700\u5927 100MB")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "\u4e0a\u4f20\u6210\u529f"),
            @ApiResponse(responseCode = "400", description = "\u4e0a\u4f20\u5931\u8d25\uff0c\u6587\u4ef6\u683c\u5f0f\u4e0d\u652f\u6301\u6216\u5927\u5c0f\u8d85\u9650"),
            @ApiResponse(responseCode = "401", description = "\u672a\u6388\u6743")
    })
    @PostMapping("/video")
    public ResponseEntity<ResponseDTO<FileUploadResultDTO>> uploadVideo(
            @RequestAttribute("userId") Long userId,
            @Parameter(name = "file", description = "\u89c6\u9891\u6587\u4ef6", required = true) @RequestParam("file") MultipartFile file) {
        try {
            FileUploadResultDTO result = fileUploadService.uploadVideo(file, userId);
            return ResponseEntity.ok(ResponseDTO.success(result));
        } catch (IOException e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "\u4e0a\u4f20\u97f3\u9891", description = "\u652f\u6301 mp3/wav/aac/ogg/m4a\uff0c\u6700\u5927 10MB")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "\u4e0a\u4f20\u6210\u529f"),
            @ApiResponse(responseCode = "400", description = "\u4e0a\u4f20\u5931\u8d25\uff0c\u6587\u4ef6\u683c\u5f0f\u4e0d\u652f\u6301\u6216\u5927\u5c0f\u8d85\u9650"),
            @ApiResponse(responseCode = "401", description = "\u672a\u6388\u6743")
    })
    @PostMapping("/audio")
    public ResponseEntity<ResponseDTO<FileUploadResultDTO>> uploadAudio(
            @RequestAttribute("userId") Long userId,
            @Parameter(name = "file", description = "\u97f3\u9891\u6587\u4ef6", required = true) @RequestParam("file") MultipartFile file) {
        try {
            FileUploadResultDTO result = fileUploadService.uploadAudio(file, userId);
            return ResponseEntity.ok(ResponseDTO.success(result));
        } catch (IOException e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }
}
