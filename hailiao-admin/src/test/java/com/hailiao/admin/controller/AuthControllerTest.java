package com.hailiao.admin.controller;

import com.hailiao.common.entity.AdminUser;
import com.hailiao.common.service.AdminUserService;
import com.hailiao.common.util.AdminJwtUtil;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    @Mock
    private AdminUserService adminUserService;

    @Mock
    private AdminJwtUtil adminJwtUtil;

    @InjectMocks
    private AuthController authController;

    @Test
    void getCurrentAdminReturnsEffectivePermissions() {
        AdminUser adminUser = new AdminUser();
        adminUser.setId(8L);
        adminUser.setUsername("boss");
        adminUser.setName("Boss");
        adminUser.setRole(1);
        adminUser.setPermissions("*");
        adminUser.setStatus(1);

        Set<String> permissions = new LinkedHashSet<String>();
        permissions.add("*");

        Map<String, Object> adminResponse = new LinkedHashMap<String, Object>();
        adminResponse.put("id", 8L);
        adminResponse.put("username", "boss");
        adminResponse.put("roleName", "\u8d85\u7ea7\u7ba1\u7406\u5458");
        adminResponse.put("effectivePermissions", permissions);

        when(adminUserService.getAdminUserById(8L)).thenReturn(adminUser);
        when(adminUserService.toAdminResponse(adminUser)).thenReturn(adminResponse);

        ResponseEntity<?> actual = authController.getCurrentAdmin(8L);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals("boss", body.get("username"));
        assertEquals("\u8d85\u7ea7\u7ba1\u7406\u5458", body.get("roleName"));
        assertEquals(permissions, body.get("effectivePermissions"));
        verify(adminUserService).getAdminUserById(8L);
        verify(adminUserService).toAdminResponse(adminUser);
    }

    @Test
    void loginReturnsUnauthorizedWhenCredentialsAreInvalid() {
        when(adminUserService.login("boss", "bad")).thenThrow(new RuntimeException("\u5bc6\u7801\u9519\u8bef"));

        ResponseEntity<?> actual = authController.login(stringMapOf("username", "boss", "password", "bad"));

        assertEquals(HttpStatus.UNAUTHORIZED, actual.getStatusCode());
        assertTrue(String.valueOf(actual.getBody()).contains("\u5bc6\u7801\u9519\u8bef"));
        verify(adminUserService).login("boss", "bad");
    }

    @Test
    void getCurrentAdminContextReturnsBootstrapPayload() {
        AdminUser adminUser = new AdminUser();
        adminUser.setId(9L);

        Map<String, Object> adminMap = new LinkedHashMap<String, Object>();
        adminMap.put("id", 9L);
        adminMap.put("username", "root");

        List<String> permissionOptions = new ArrayList<String>();
        permissionOptions.add("admin:manage");

        Map<String, Object> context = new LinkedHashMap<String, Object>();
        context.put("admin", adminMap);
        context.put("permissionOptions", permissionOptions);
        context.put("roleOptions", new ArrayList<Object>());

        when(adminUserService.getAdminUserById(9L)).thenReturn(adminUser);
        when(adminUserService.buildAdminContext(adminUser)).thenReturn(context);

        ResponseEntity<?> actual = authController.getCurrentAdminContext(9L);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        assertSame(context, actual.getBody());
        verify(adminUserService).getAdminUserById(9L);
        verify(adminUserService).buildAdminContext(adminUser);
    }

    @Test
    void updateCurrentAdminProfileReturnsUpdatedContext() {
        AdminUser adminUser = new AdminUser();
        adminUser.setId(10L);

        Map<String, Object> adminMap = new LinkedHashMap<String, Object>();
        adminMap.put("id", 10L);
        adminMap.put("name", "New Name");

        Map<String, Object> context = new LinkedHashMap<String, Object>();
        context.put("admin", adminMap);

        when(adminUserService.updateOwnProfile(10L, "New Name")).thenReturn(adminUser);
        when(adminUserService.buildAdminContext(adminUser)).thenReturn(context);

        ResponseEntity<?> actual = authController.updateCurrentAdminProfile(10L, stringMapOf("name", "New Name"));

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        assertSame(context, actual.getBody());
        verify(adminUserService).updateOwnProfile(10L, "New Name");
        verify(adminUserService).buildAdminContext(adminUser);
    }

    @Test
    void changeCurrentAdminPasswordReturnsRefreshHint() {
        doNothing().when(adminUserService).changePassword(11L, "old123", "new123");

        ResponseEntity<?> actual = authController.changeCurrentAdminPassword(
                11L,
                stringMapOf("oldPassword", "old123", "newPassword", "new123")
        );

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals("\u5bc6\u7801\u4fee\u6539\u6210\u529f", body.get("message"));
        assertEquals(Boolean.TRUE, body.get("requireLoginRefresh"));
        verify(adminUserService).changePassword(11L, "old123", "new123");
    }

    @Test
    void changeCurrentAdminPasswordRejectsMissingFields() {
        ResponseEntity<?> actual = authController.changeCurrentAdminPassword(
                11L,
                stringMapOf("oldPassword", "old123")
        );

        assertEquals(HttpStatus.BAD_REQUEST, actual.getStatusCode());
        assertTrue(String.valueOf(actual.getBody()).contains("\u539f\u5bc6\u7801\u548c\u65b0\u5bc6\u7801\u4e0d\u80fd\u4e3a\u7a7a"));
    }

    @Test
    void updateCurrentAdminProfileReturnsBadRequestWhenNameTooLong() {
        String longName = repeat("x", 51);
        doThrow(new RuntimeException("\u6635\u79f0\u957f\u5ea6\u4e0d\u80fd\u8d85\u8fc7 50 \u4e2a\u5b57\u7b26"))
                .when(adminUserService).updateOwnProfile(10L, longName);

        ResponseEntity<?> actual = authController.updateCurrentAdminProfile(10L, stringMapOf("name", longName));

        assertEquals(HttpStatus.BAD_REQUEST, actual.getStatusCode());
        assertTrue(String.valueOf(actual.getBody()).contains("\u6635\u79f0\u957f\u5ea6"));
        verify(adminUserService).updateOwnProfile(10L, longName);
    }

    private Map<String, Object> mapOf(Object... values) {
        LinkedHashMap<String, Object> map = new LinkedHashMap<String, Object>();
        for (int i = 0; i < values.length; i += 2) {
            map.put(String.valueOf(values[i]), values[i + 1]);
        }
        return map;
    }

    private Map<String, String> stringMapOf(String... values) {
        LinkedHashMap<String, String> map = new LinkedHashMap<String, String>();
        for (int i = 0; i < values.length; i += 2) {
            map.put(values[i], values[i + 1]);
        }
        return map;
    }

    private String repeat(String value, int count) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < count; i++) {
            builder.append(value);
        }
        return builder.toString();
    }
}
