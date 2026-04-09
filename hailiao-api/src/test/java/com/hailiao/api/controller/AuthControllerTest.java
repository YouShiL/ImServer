package com.hailiao.api.controller;

import com.hailiao.api.dto.LoginRequestDTO;
import com.hailiao.api.dto.RegisterRequestDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.api.dto.UserSessionDTO;
import com.hailiao.api.wukong.WukongUserTokenSyncService;
import com.hailiao.common.entity.User;
import com.hailiao.common.entity.UserSession;
import com.hailiao.common.service.UserService;
import com.hailiao.common.service.UserSessionService;
import com.hailiao.common.util.AppJwtUtil;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import javax.servlet.http.HttpServletRequest;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    @Mock
    private UserService userService;

    @Mock
    private AppJwtUtil jwtUtil;

    @Mock
    private UserSessionService userSessionService;

    @Mock
    private HttpServletRequest httpServletRequest;

    @Mock
    private WukongUserTokenSyncService wukongUserTokenSyncService;

    @InjectMocks
    private AuthController authController;

    @Test
    void registerShouldRejectMissingPhone() {
        RegisterRequestDTO request = new RegisterRequestDTO();
        request.setPassword("123456");

        ResponseEntity<ResponseDTO<Map<String, Object>>> response =
                authController.register(request, httpServletRequest);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(400, response.getBody().getCode());
    }

    @Test
    void loginShouldRejectMissingPassword() {
        LoginRequestDTO request = new LoginRequestDTO();
        request.setPhone("13800138000");

        ResponseEntity<ResponseDTO<Map<String, Object>>> response =
                authController.login(request, httpServletRequest);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(400, response.getBody().getCode());
    }

    @Test
    void loginShouldReturnForbiddenWhenDeviceLockBlocksNewDevice() {
        LoginRequestDTO request = new LoginRequestDTO();
        request.setPhone("13800138000");
        request.setPassword("123456");
        request.setDeviceId("device-2");

        User user = buildUser(1L, "13800138000");
        user.setDeviceLock(true);

        when(userService.validateLogin("13800138000", "123456")).thenReturn(user);
        when(userSessionService.hasActiveSessionOnOtherDevice(1L, "device-2")).thenReturn(true);
        when(httpServletRequest.getRemoteAddr()).thenReturn("127.0.0.1");

        ResponseEntity<ResponseDTO<Map<String, Object>>> response =
                authController.login(request, httpServletRequest);

        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());
        assertEquals(403, response.getBody().getCode());
    }

    @Test
    void loginShouldReturnTokenAndSessionOnSuccess() {
        LoginRequestDTO request = new LoginRequestDTO();
        request.setPhone("13800138000");
        request.setPassword("123456");
        request.setDeviceId("device-1");
        request.setDeviceName("Windows PC");
        request.setDeviceType("windows");

        User loginUser = buildUser(1L, "13800138000");
        loginUser.setDeviceLock(false);
        loginUser.setLastLoginIp("10.0.0.1");

        User updatedUser = buildUser(1L, "13800138000");
        updatedUser.setDeviceLock(false);
        updatedUser.setLastLoginIp("127.0.0.1");

        UserSession session = buildSession("session-1", "device-1", true);

        when(userService.validateLogin("13800138000", "123456")).thenReturn(loginUser);
        when(userSessionService.hasActiveSessionOnOtherDevice(1L, "device-1")).thenReturn(false);
        when(httpServletRequest.getRemoteAddr()).thenReturn("127.0.0.1");
        when(httpServletRequest.getHeader(anyString())).thenReturn(null);
        when(httpServletRequest.getHeader("User-Agent")).thenReturn("JUnit");
        when(userSessionService.createSession(anyLong(), anyString(), anyString(), anyString(),
                anyString(), anyString())).thenReturn(session);
        when(userService.markLoginSuccess(anyLong(), anyString())).thenReturn(updatedUser);
        when(jwtUtil.generateToken(anyLong(), anyString(), eq(1), anyString())).thenReturn("jwt-token");

        ResponseEntity<ResponseDTO<Map<String, Object>>> response =
                authController.login(request, httpServletRequest);

        assertEquals(200, response.getBody().getCode(), response.getBody().getMessage());
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(200, response.getBody().getCode());
        assertEquals("jwt-token", response.getBody().getData().get("token"));
        assertEquals("session-1", response.getBody().getData().get("sessionId"));
        assertNotNull(response.getBody().getData().get("loginNotice"));
    }

    @Test
    void getSessionsShouldMarkCurrentSession() {
        List<UserSession> sessions = new ArrayList<UserSession>();
        sessions.add(buildSession("current-session", "device-1", true));
        sessions.add(buildSession("old-session", "device-2", false));

        when(userSessionService.getUserSessions(1L)).thenReturn(sessions);

        ResponseEntity<ResponseDTO<List<UserSessionDTO>>> response =
                authController.getSessions(1L, "current-session");

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(2, response.getBody().getData().size());
        assertTrue(response.getBody().getData().get(0).getCurrentSession());
        assertFalse(response.getBody().getData().get(1).getCurrentSession());
    }

    @Test
    void terminateOtherSessionsShouldDelegateAndReturnSuccess() {
        doNothing().when(userSessionService).revokeOtherSessions(1L, "current-session");

        ResponseEntity<ResponseDTO<String>> response =
                authController.terminateOtherSessions(1L, "current-session");

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(200, response.getBody().getCode());
        verify(userSessionService).revokeOtherSessions(1L, "current-session");
    }

    private User buildUser(Long id, String phone) {
        User user = new User();
        user.setId(id);
        user.setPhone(phone);
        user.setNickname("tester");
        user.setDeviceLock(false);
        return user;
    }

    private UserSession buildSession(String sessionId, String deviceId, boolean active) {
        UserSession session = new UserSession();
        session.setId(1L);
        session.setSessionId(sessionId);
        session.setDeviceId(deviceId);
        session.setDeviceName("test-device");
        session.setDeviceType("windows");
        session.setLoginIp("127.0.0.1");
        session.setIsActive(active);
        session.setCreatedAt(new Date());
        session.setLastActiveAt(new Date());
        return session;
    }
}
