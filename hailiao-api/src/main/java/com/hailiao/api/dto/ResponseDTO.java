package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "通用响应DTO - 所有API接口的统一响应格式")
public class ResponseDTO<T> {

    @Schema(description = "响应状态码", type = "int", example = "200", title = "200:成功 400:参数错误 401:未授权 403:禁止访问 404:资源不存在 500:服务器错误")
    private int code;

    @Schema(description = "响应消息", type = "String", example = "操作成功", title = "对响应状态的文字描述")
    private String message;

    @Schema(description = "响应数据", title = "具体的数据内容，类型根据接口而定")
    private T data;

    public static <T> ResponseDTO<T> success(T data) {
        ResponseDTO<T> response = new ResponseDTO<>();
        response.setCode(200);
        response.setMessage("操作成功");
        response.setData(data);
        return response;
    }

    public static <T> ResponseDTO<T> success() {
        return success(null);
    }

    public static <T> ResponseDTO<T> error(int code, String message) {
        ResponseDTO<T> response = new ResponseDTO<>();
        response.setCode(code);
        response.setMessage(message);
        response.setData(null);
        return response;
    }

    public static <T> ResponseDTO<T> badRequest(String message) {
        return error(400, message);
    }

    public static <T> ResponseDTO<T> unauthorized(String message) {
        return error(401, message);
    }

    public static <T> ResponseDTO<T> serverError(String message) {
        return error(500, message);
    }

    public int getCode() { return code; }
    public void setCode(int code) { this.code = code; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    public T getData() { return data; }
    public void setData(T data) { this.data = data; }
}
