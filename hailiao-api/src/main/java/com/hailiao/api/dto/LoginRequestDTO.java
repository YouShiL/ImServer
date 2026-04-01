package com.hailiao.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "登录请求 DTO")
public class LoginRequestDTO {

    @Schema(description = "手机号", required = true, example = "13800138000")
    private String phone;

    @Schema(description = "密码", required = true, example = "123456")
    private String password;

    @Schema(description = "设备唯一标识", example = "device-abc123")
    private String deviceId;

    @Schema(description = "设备名称", example = "Windows Desktop")
    private String deviceName;

    @Schema(description = "设备类型", example = "windows")
    private String deviceType;

    @Schema(description = "是否替换其他设备登录", example = "false")
    private Boolean replaceExistingSession;

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }

    public String getDeviceName() { return deviceName; }
    public void setDeviceName(String deviceName) { this.deviceName = deviceName; }

    public String getDeviceType() { return deviceType; }
    public void setDeviceType(String deviceType) { this.deviceType = deviceType; }

    public Boolean getReplaceExistingSession() { return replaceExistingSession; }
    public void setReplaceExistingSession(Boolean replaceExistingSession) { this.replaceExistingSession = replaceExistingSession; }
}
