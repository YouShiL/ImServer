package com.hailiao.api.controller;

import com.hailiao.api.dto.LoginRequestDTO;
import com.hailiao.api.dto.RegisterRequestDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.api.dto.UserSessionDTO;
import com.hailiao.common.entity.User;
import com.hailiao.common.entity.UserSession;
import com.hailiao.common.service.UserService;
import com.hailiao.common.service.UserSessionService;
import com.hailiao.common.util.AppJwtUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Tag(name = "认证管理", description = "用户认证相关接口")
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private UserService userService;

    @Autowired
    private AppJwtUtil jwtUtil;

    @Autowired
    private UserSessionService userSessionService;

    @Operation(summary = "用户注册", description = "创建新用户账号并返回 JWT 令牌")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "注册成功", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
            @ApiResponse(responseCode = "400", description = "注册失败", content = @Content(schema = @Schema(implementation = ResponseDTO.class)))
    })
    @PostMapping("/register")
    public ResponseEntity<ResponseDTO<Map<String, Object>>> register(
            @Parameter(name = "request", required = true, schema = @Schema(implementation = RegisterRequestDTO.class))
            @RequestBody RegisterRequestDTO request,
            HttpServletRequest httpRequest) {
        try {
            if (request.getPhone() == null || request.getPassword() == null) {
                return ResponseEntity.badRequest().body(ResponseDTO.badRequest("手机号和密码不能为空"));
            }

            User user = new User();
            user.setPhone(request.getPhone());
            user.setPassword(request.getPassword());
            user.setNickname(request.getNickname());

            User registeredUser = userService.register(user);
            String loginIp = resolveClientIp(httpRequest);
            UserSession session = userSessionService.createSession(
                    registeredUser.getId(),
                    null,
                    resolveDeviceName(null, httpRequest),
                    "unknown",
                    loginIp,
                    httpRequest.getHeader("User-Agent"));
            User loginUser = userService.markLoginSuccess(registeredUser.getId(), loginIp);
            String token = jwtUtil.generateToken(loginUser.getId(), loginUser.getPhone(), 1, session.getSessionId());

            return ResponseEntity.ok(ResponseDTO.success(buildAuthResponse(loginUser, token, session, null)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "用户登录", description = "验证手机号密码并建立设备会话")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "登录成功", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
            @ApiResponse(responseCode = "401", description = "登录失败", content = @Content(schema = @Schema(implementation = ResponseDTO.class))),
            @ApiResponse(responseCode = "403", description = "设备锁拦截", content = @Content(schema = @Schema(implementation = ResponseDTO.class)))
    })
    @PostMapping("/login")
    public ResponseEntity<ResponseDTO<Map<String, Object>>> login(
            @Parameter(name = "request", required = true, schema = @Schema(implementation = LoginRequestDTO.class))
            @RequestBody LoginRequestDTO request,
            HttpServletRequest httpRequest) {
        try {
            if (request.getPhone() == null || request.getPassword() == null) {
                return ResponseEntity.badRequest().body(ResponseDTO.badRequest("手机号和密码不能为空"));
            }

            User user = userService.validateLogin(request.getPhone(), request.getPassword());
            String loginIp = resolveClientIp(httpRequest);
            boolean hasOtherDevice = userSessionService.hasActiveSessionOnOtherDevice(user.getId(), request.getDeviceId());
            if (Boolean.TRUE.equals(user.getDeviceLock())
                    && hasOtherDevice
                    && !Boolean.TRUE.equals(request.getReplaceExistingSession())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(ResponseDTO.error(403, "设备锁已开启，请先在已登录设备中关闭设备锁或退出其他设备"));
            }
            if (Boolean.TRUE.equals(request.getReplaceExistingSession()) && hasOtherDevice) {
                userSessionService.revokeOtherSessions(user.getId(), null);
            }

            String loginNotice = buildLoginNotice(user, loginIp);
            UserSession session = userSessionService.createSession(
                    user.getId(),
                    request.getDeviceId(),
                    resolveDeviceName(request.getDeviceName(), httpRequest),
                    resolveDeviceType(request.getDeviceType()),
                    loginIp,
                    httpRequest.getHeader("User-Agent"));
            User updatedUser = userService.markLoginSuccess(user.getId(), loginIp);
            String token = jwtUtil.generateToken(updatedUser.getId(), updatedUser.getPhone(), 1, session.getSessionId());

            return ResponseEntity.ok(ResponseDTO.success(buildAuthResponse(updatedUser, token, session, loginNotice)));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ResponseDTO.unauthorized(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ResponseDTO.unauthorized("登录失败"));
        }
    }

    @Operation(summary = "用户登出", description = "使当前设备会话失效")
    @PostMapping("/logout")
    public ResponseEntity<ResponseDTO<String>> logout(@RequestAttribute("userId") Long userId,
                                                      @RequestAttribute(value = "sessionId", required = false) String sessionId) {
        try {
            userSessionService.revokeCurrentSession(userId, sessionId);
            return ResponseEntity.ok(ResponseDTO.success("退出登录成功"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "刷新令牌", description = "保留当前会话并刷新 JWT")
    @PostMapping("/refresh")
    public ResponseEntity<ResponseDTO<String>> refreshToken(@RequestAttribute("userId") Long userId,
                                                            @RequestAttribute("username") String username,
                                                            @RequestAttribute(value = "sessionId", required = false) String sessionId) {
        try {
            String newToken = jwtUtil.generateToken(userId, username, 1, sessionId);
            return ResponseEntity.ok(ResponseDTO.success(newToken));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "获取设备会话列表", description = "查看当前账号的登录设备")
    @GetMapping("/sessions")
    public ResponseEntity<ResponseDTO<List<UserSessionDTO>>> getSessions(@RequestAttribute("userId") Long userId,
                                                                         @RequestAttribute(value = "sessionId", required = false) String currentSessionId) {
        try {
            List<UserSessionDTO> result = new ArrayList<>();
            for (UserSession session : userSessionService.getUserSessions(userId)) {
                result.add(toSessionDTO(session, currentSessionId));
            }
            return ResponseEntity.ok(ResponseDTO.success(result));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "移除指定设备", description = "强制指定设备下线")
    @DeleteMapping("/session/{sessionId}")
    public ResponseEntity<ResponseDTO<String>> revokeSession(@RequestAttribute("userId") Long userId,
                                                             @PathVariable String sessionId,
                                                             @RequestAttribute(value = "sessionId", required = false) String currentSessionId) {
        try {
            userSessionService.revokeSession(userId, sessionId);
            userSessionService.refreshUserOnlineStatus(userId);
            String message = sessionId.equals(currentSessionId) ? "当前设备已退出登录" : "设备会话已下线";
            return ResponseEntity.ok(ResponseDTO.success(message));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    @Operation(summary = "移除其他设备", description = "保留当前设备，强制其他设备全部下线")
    @PostMapping("/session/terminate-others")
    public ResponseEntity<ResponseDTO<String>> terminateOtherSessions(@RequestAttribute("userId") Long userId,
                                                                      @RequestAttribute(value = "sessionId", required = false) String currentSessionId) {
        try {
            userSessionService.revokeOtherSessions(userId, currentSessionId);
            return ResponseEntity.ok(ResponseDTO.success("其他设备已下线"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ResponseDTO.badRequest(e.getMessage()));
        }
    }

    private Map<String, Object> buildAuthResponse(User user, String token, UserSession session, String loginNotice) {
        Map<String, Object> data = new HashMap<>();
        data.put("user", user);
        data.put("token", token);
        data.put("sessionId", session.getSessionId());
        data.put("deviceLock", user.getDeviceLock());
        if (loginNotice != null && !loginNotice.trim().isEmpty()) {
            data.put("loginNotice", loginNotice);
        }
        return data;
    }

    private UserSessionDTO toSessionDTO(UserSession session, String currentSessionId) {
        UserSessionDTO dto = new UserSessionDTO();
        dto.setSessionId(session.getSessionId());
        dto.setDeviceId(session.getDeviceId());
        dto.setDeviceName(session.getDeviceName());
        dto.setDeviceType(session.getDeviceType());
        dto.setLoginIp(session.getLoginIp());
        dto.setActive(session.getIsActive());
        dto.setCurrentSession(session.getSessionId() != null && session.getSessionId().equals(currentSessionId));
        dto.setCreatedAt(session.getCreatedAt());
        dto.setLastActiveAt(session.getLastActiveAt());
        dto.setRevokedAt(session.getRevokedAt());
        return dto;
    }

    private String resolveClientIp(HttpServletRequest request) {
        String[] headers = {"X-Forwarded-For", "X-Real-IP", "Proxy-Client-IP", "WL-Proxy-Client-IP"};
        for (String header : headers) {
            String value = request.getHeader(header);
            if (value != null && !value.trim().isEmpty() && !"unknown".equalsIgnoreCase(value)) {
                return value.split(",")[0].trim();
            }
        }
        return request.getRemoteAddr();
    }

    private String resolveDeviceName(String deviceName, HttpServletRequest request) {
        if (deviceName != null && !deviceName.trim().isEmpty()) {
            return deviceName.trim();
        }
        String userAgent = request.getHeader("User-Agent");
        if (userAgent == null || userAgent.trim().isEmpty()) {
            return "\u672a\u77e5\u8bbe\u5907";
        }
        return userAgent.length() > 100 ? userAgent.substring(0, 100) : userAgent;
    }

    private String resolveDeviceType(String deviceType) {
        if (deviceType == null || deviceType.trim().isEmpty()) {
            return "unknown";
        }
        return deviceType.trim().toLowerCase();
    }

    private String buildLoginNotice(User user, String currentIp) {
        if (user.getLastLoginIp() == null || user.getLastLoginIp().trim().isEmpty()) {
            return null;
        }
        if (!user.getLastLoginIp().equals(currentIp)) {
            return "检测到本次登录 IP 与上次不同，请确认是否为本人操作";
        }
        return null;
    }
}
