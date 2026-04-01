package com.hailiao.admin.controller;

import com.hailiao.common.entity.AdminUser;
import com.hailiao.common.service.AdminUserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminManageControllerTest {

    @Mock
    private AdminUserService adminUserService;

    @InjectMocks
    private AdminManageController adminManageController;

    @Test
    void getAdminStatsReturnsStructuredSummary() {
        Map<String, Object> riskStats = new LinkedHashMap<String, Object>();
        riskStats.put("critical", mapOf("riskLevel", "critical", "riskLabel", "\u6781\u9ad8\u98ce\u9669", "count", 1));
        riskStats.put("high", mapOf("riskLevel", "high", "riskLabel", "\u9ad8\u98ce\u9669", "count", 2));
        riskStats.put("medium", mapOf("riskLevel", "medium", "riskLabel", "\u4e2d\u98ce\u9669", "count", 2));
        riskStats.put("low", mapOf("riskLevel", "low", "riskLabel", "\u4f4e\u98ce\u9669", "count", 1));

        Map<String, Object> expected = new LinkedHashMap<String, Object>();
        expected.put("totalAdmins", 6L);
        expected.put("activeAdmins", 5L);
        expected.put("disabledAdmins", 1L);
        expected.put("riskStats", riskStats);
        when(adminUserService.getAdminStatsSummary()).thenReturn(expected);

        ResponseEntity<?> actual = adminManageController.getAdminStats();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        assertSame(expected, actual.getBody());
        verify(adminUserService).getAdminStatsSummary();
    }

    @Test
    void getAdminListReturnsSummaryBlock() {
        AdminUser adminUser = new AdminUser();
        adminUser.setId(1L);
        adminUser.setUsername("ops");
        adminUser.setRole(5);

        List<AdminUser> admins = new ArrayList<AdminUser>();
        admins.add(adminUser);
        Page<AdminUser> page = new PageImpl<AdminUser>(admins, PageRequest.of(0, 20), 1);

        Map<String, Object> riskStats = new LinkedHashMap<String, Object>();
        riskStats.put("low", mapOf("riskLevel", "low", "riskLabel", "\u4f4e\u98ce\u9669", "count", 1));

        Map<String, Object> summary = new LinkedHashMap<String, Object>();
        summary.put("filteredTotal", 1);
        summary.put("activeCount", 1);
        summary.put("disabledCount", 0);
        summary.put("riskStats", riskStats);

        Map<String, Object> adminResponse = new LinkedHashMap<String, Object>();
        adminResponse.put("id", 1L);
        adminResponse.put("username", "ops");
        adminResponse.put("statusLabel", "\u542f\u7528");
        adminResponse.put("roleDescription", "\u4e3b\u8981\u8d1f\u8d23\u8fd0\u8425\u914d\u7f6e\u3001\u7edf\u8ba1\u548c\u90e8\u5206\u7528\u6237/\u7fa4\u7ec4\u7ba1\u7406");
        adminResponse.put("permissionSummary", "statistics:view");
        adminResponse.put("effectivePermissionCount", 1);
        adminResponse.put("permissionRiskLevel", "low");
        adminResponse.put("permissionRiskLabel", "\u4f4e\u98ce\u9669");

        when(adminUserService.getAdminUserList("ops", 5, 1, PageRequest.of(0, 20, org.springframework.data.domain.Sort.by("createdAt").descending())))
                .thenReturn(page);
        when(adminUserService.getAdminListSummary("ops", 5, 1)).thenReturn(summary);
        when(adminUserService.toAdminResponse(adminUser)).thenReturn(adminResponse);

        ResponseEntity<?> actual = adminManageController.getAdminList("ops", 5, 1, 0, 20);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertSame(summary, body.get("summary"));
        Map<?, ?> summaryBlock = assertInstanceOf(Map.class, body.get("summary"));
        Map<?, ?> returnedRiskStats = assertInstanceOf(Map.class, summaryBlock.get("riskStats"));
        Map<?, ?> lowRisk = assertInstanceOf(Map.class, returnedRiskStats.get("low"));
        assertEquals("\u4f4e\u98ce\u9669", lowRisk.get("riskLabel"));

        List<?> content = assertInstanceOf(List.class, body.get("content"));
        Map<?, ?> firstItem = assertInstanceOf(Map.class, content.get(0));
        assertEquals("\u542f\u7528", firstItem.get("statusLabel"));
        assertTrue(String.valueOf(firstItem.get("roleDescription")).contains("\u8fd0\u8425"));
        assertEquals("statistics:view", firstItem.get("permissionSummary"));
        assertEquals(1, firstItem.get("effectivePermissionCount"));
        assertEquals("low", firstItem.get("permissionRiskLevel"));
        assertEquals("\u4f4e\u98ce\u9669", firstItem.get("permissionRiskLabel"));
        verify(adminUserService).getAdminListSummary("ops", 5, 1);
    }

    @Test
    void exportAdminsReturnsCsvAttachment() {
        AdminUser adminUser = new AdminUser();
        adminUser.setId(3L);
        adminUser.setUsername("audit");
        adminUser.setRole(2);
        adminUser.setStatus(1);

        List<AdminUser> admins = new ArrayList<AdminUser>();
        admins.add(adminUser);
        Page<AdminUser> page = new PageImpl<AdminUser>(admins);

        when(adminUserService.getAdminUserList(null, null, null, org.springframework.data.domain.Pageable.unpaged()))
                .thenReturn(page);
        when(adminUserService.getRoleName(2)).thenReturn("\u5ba1\u6838\u7ba1\u7406\u5458");

        ResponseEntity<?> actual = adminManageController.exportAdmins(null, null, null);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        assertTrue(String.valueOf(actual.getHeaders().getFirst(HttpHeaders.CONTENT_DISPOSITION)).contains("admin-list.csv"));
        assertTrue(String.valueOf(actual.getBody()).contains("audit"));
        assertTrue(String.valueOf(actual.getBody()).contains("\u6709\u6548\u6743\u9650\u6570"));
    }

    @Test
    void getRoleOptionsReturnsBuiltInTemplates() {
        List<Map<String, Object>> expected = new ArrayList<Map<String, Object>>();
        expected.add(mapOf("role", 1, "roleName", "\u8d85\u7ea7\u7ba1\u7406\u5458", "description", "\u62e5\u6709\u6240\u6709\u540e\u53f0\u6a21\u5757\u548c\u6743\u9650"));
        expected.add(mapOf("role", 2, "roleName", "\u5ba1\u6838\u7ba1\u7406\u5458", "description", "\u4e3b\u8981\u8d1f\u8d23\u5ba1\u6838"));
        when(adminUserService.getRoleTemplates()).thenReturn(expected);

        ResponseEntity<?> actual = adminManageController.getRoleOptions();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        assertSame(expected, actual.getBody());
        verify(adminUserService).getRoleTemplates();
    }

    @Test
    void previewPermissionsReturnsRoleNameAndEffectivePermissions() {
        LinkedHashSet<String> effectivePermissions = new LinkedHashSet<String>();
        effectivePermissions.add("user:manage");
        effectivePermissions.add("report:manage");

        when(adminUserService.getRoleName(3)).thenReturn("\u5ba2\u670d\u7ba1\u7406\u5458");
        when(adminUserService.getEffectivePermissions(3, "user:manage,report:manage"))
                .thenReturn(effectivePermissions);

        ResponseEntity<?> actual = adminManageController.previewPermissions(
                mapOf("role", 3, "permissions", "user:manage,report:manage")
        );

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals("\u5ba2\u670d\u7ba1\u7406\u5458", body.get("roleName"));
        assertEquals(effectivePermissions, body.get("effectivePermissions"));
        verify(adminUserService).getRoleName(3);
        verify(adminUserService).getEffectivePermissions(3, "user:manage,report:manage");
    }

    @Test
    void getAdminByIdReturnsStatusAndPermissionSummaryFields() {
        AdminUser adminUser = new AdminUser();
        adminUser.setId(8L);
        adminUser.setUsername("security-admin");
        adminUser.setRole(1);
        adminUser.setStatus(1);
        adminUser.setPermissions("user:manage,group:manage");

        Map<String, Object> adminResponse = new LinkedHashMap<String, Object>();
        adminResponse.put("id", 8L);
        adminResponse.put("username", "security-admin");
        adminResponse.put("status", 1);
        adminResponse.put("statusLabel", "\u542f\u7528");
        adminResponse.put("roleDescription", "\u62e5\u6709\u6240\u6709\u540e\u53f0\u6a21\u5757\u548c\u6743\u9650\uff0c\u9002\u5408\u7cfb\u7edf\u8d1f\u8d23\u4eba");
        adminResponse.put("permissionSummary", "user:manage,group:manage");
        adminResponse.put("effectivePermissionCount", 1);
        adminResponse.put("hasWildcardPermission", true);
        adminResponse.put("permissionRiskLevel", "critical");
        adminResponse.put("permissionRiskLabel", "\u6781\u9ad8\u98ce\u9669");

        when(adminUserService.getAdminUserById(8L)).thenReturn(adminUser);
        when(adminUserService.toAdminResponse(adminUser)).thenReturn(adminResponse);

        ResponseEntity<?> actual = adminManageController.getAdminById(8L);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals("\u542f\u7528", body.get("statusLabel"));
        assertTrue(String.valueOf(body.get("roleDescription")).contains("\u6240\u6709\u540e\u53f0"));
        assertEquals("user:manage,group:manage", body.get("permissionSummary"));
        assertEquals(1, body.get("effectivePermissionCount"));
        assertEquals(Boolean.TRUE, body.get("hasWildcardPermission"));
        assertEquals("critical", body.get("permissionRiskLevel"));
        assertEquals("\u6781\u9ad8\u98ce\u9669", body.get("permissionRiskLabel"));
    }

    @Test
    void getAdminByIdDoesNotExposePassword() {
        AdminUser adminUser = new AdminUser();
        adminUser.setId(12L);
        adminUser.setUsername("alice");
        adminUser.setPassword("secret");
        adminUser.setRole(2);

        Map<String, Object> adminResponse = new LinkedHashMap<String, Object>();
        adminResponse.put("id", 12L);
        adminResponse.put("username", "alice");
        adminResponse.put("roleName", "\u5ba1\u6838\u7ba1\u7406\u5458");

        when(adminUserService.getAdminUserById(12L)).thenReturn(adminUser);
        when(adminUserService.toAdminResponse(adminUser)).thenReturn(adminResponse);

        ResponseEntity<?> actual = adminManageController.getAdminById(12L);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertFalse(body.containsKey("password"));
        assertEquals("\u5ba1\u6838\u7ba1\u7406\u5458", body.get("roleName"));
        verify(adminUserService).getAdminUserById(12L);
    }

    @Test
    void createAdminReturnsSanitizedAdminPayload() {
        AdminUser adminUser = new AdminUser();
        adminUser.setId(20L);
        adminUser.setUsername("new-admin");
        adminUser.setPassword("encoded");
        adminUser.setRole(5);

        Map<String, Object> adminResponse = new LinkedHashMap<String, Object>();
        adminResponse.put("id", 20L);
        adminResponse.put("username", "new-admin");
        adminResponse.put("roleName", "\u8fd0\u8425\u7ba1\u7406\u5458");

        when(adminUserService.createAdminUser(adminUser)).thenReturn(adminUser);
        when(adminUserService.toAdminResponse(adminUser)).thenReturn(adminResponse);

        ResponseEntity<?> actual = adminManageController.createAdmin(adminUser, null);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals("new-admin", body.get("username"));
        assertFalse(body.containsKey("password"));
        assertEquals("\u8fd0\u8425\u7ba1\u7406\u5458", body.get("roleName"));
        verify(adminUserService).createAdminUser(adminUser);
    }

    @Test
    void updateAdminReturnsBadRequestWhenTryingToDisableCurrentAdmin() {
        AdminUser adminUser = new AdminUser();
        adminUser.setStatus(0);
        doThrow(new RuntimeException("\u4e0d\u80fd\u7981\u7528\u5f53\u524d\u767b\u5f55\u7ba1\u7406\u5458"))
                .when(adminUserService).updateAdminUser(adminUser, 7L);

        ResponseEntity<?> actual = adminManageController.updateAdmin(7L, adminUser, 7L, null);

        assertEquals(HttpStatus.BAD_REQUEST, actual.getStatusCode());
        assertTrue(String.valueOf(actual.getBody()).contains("\u4e0d\u80fd\u7981\u7528\u5f53\u524d\u767b\u5f55\u7ba1\u7406\u5458"));
        verify(adminUserService).updateAdminUser(adminUser, 7L);
    }

    @Test
    void updateAdminPermissionsReturnsCurrentContextWhenSelfIsUpdated() {
        AdminUser adminUser = new AdminUser();
        adminUser.setId(15L);
        adminUser.setRole(2);

        Map<String, Object> adminResponse = mapOf("id", 15L, "roleName", "\u5ba1\u6838\u7ba1\u7406\u5458");
        Map<String, Object> currentContext = new LinkedHashMap<String, Object>();
        currentContext.put("admin", adminResponse);

        when(adminUserService.updateAdminPermissions(15L, 2, "report:manage", 15L)).thenReturn(adminUser);
        when(adminUserService.toAdminResponse(adminUser)).thenReturn(adminResponse);
        when(adminUserService.buildAdminContext(adminUser)).thenReturn(currentContext);

        ResponseEntity<?> actual = adminManageController.updateAdminPermissions(
                15L,
                mapOf("role", 2, "permissions", "report:manage"),
                15L,
                null
        );

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals(Boolean.TRUE, body.get("affectsCurrentAdminSession"));
        assertSame(adminResponse, body.get("admin"));
        assertSame(currentContext, body.get("currentAdminContext"));
        verify(adminUserService).updateAdminPermissions(15L, 2, "report:manage", 15L);
    }

    @Test
    void updateAdminPermissionsReturnsBadRequestWhenLastSuperAdminWouldBeDowngraded() {
        doThrow(new RuntimeException("\u81f3\u5c11\u9700\u4fdd\u7559\u4e00\u4e2a\u8d85\u7ea7\u7ba1\u7406\u5458"))
                .when(adminUserService).updateAdminPermissions(1L, 2, null, 9L);

        ResponseEntity<?> actual = adminManageController.updateAdminPermissions(
                1L,
                mapOf("role", 2),
                9L,
                null
        );

        assertEquals(HttpStatus.BAD_REQUEST, actual.getStatusCode());
        assertTrue(String.valueOf(actual.getBody()).contains("\u8d85\u7ea7\u7ba1\u7406\u5458"));
        verify(adminUserService).updateAdminPermissions(1L, 2, null, 9L);
    }

    @Test
    void createAdminReturnsBadRequestWhenValidationFails() {
        AdminUser adminUser = new AdminUser();
        doThrow(new RuntimeException("\u7528\u6237\u540d\u4e0d\u80fd\u4e3a\u7a7a")).when(adminUserService).createAdminUser(adminUser);

        ResponseEntity<?> actual = adminManageController.createAdmin(adminUser, null);

        assertEquals(HttpStatus.BAD_REQUEST, actual.getStatusCode());
        assertTrue(String.valueOf(actual.getBody()).contains("\u7528\u6237\u540d\u4e0d\u80fd\u4e3a\u7a7a"));
        verify(adminUserService).createAdminUser(adminUser);
    }

    @Test
    void resetPasswordReturnsBadRequestWhenPasswordIsTooShort() {
        doThrow(new RuntimeException("\u5bc6\u7801\u957f\u5ea6\u5fc5\u987b\u5728 6 \u5230 100 \u4e2a\u5b57\u7b26\u4e4b\u95f4"))
                .when(adminUserService).resetPassword(7L, "123");

        ResponseEntity<?> actual = adminManageController.resetPassword(7L, stringMapOf("newPassword", "123"), null);

        assertEquals(HttpStatus.BAD_REQUEST, actual.getStatusCode());
        assertTrue(String.valueOf(actual.getBody()).contains("\u5bc6\u7801\u957f\u5ea6"));
        verify(adminUserService).resetPassword(7L, "123");
    }

    @Test
    void deleteAdminReturnsBadRequestWhenDeletingCurrentAdmin() {
        AdminUser targetAdmin = new AdminUser();
        targetAdmin.setId(11L);
        targetAdmin.setUsername("self");
        targetAdmin.setRole(1);

        when(adminUserService.getAdminUserById(11L)).thenReturn(targetAdmin);
        doThrow(new RuntimeException("\u4e0d\u80fd\u5220\u9664\u5f53\u524d\u767b\u5f55\u7ba1\u7406\u5458"))
                .when(adminUserService).deleteAdminUser(11L, 11L);

        ResponseEntity<?> actual = adminManageController.deleteAdmin(11L, 11L, null);

        assertEquals(HttpStatus.BAD_REQUEST, actual.getStatusCode());
        assertTrue(String.valueOf(actual.getBody()).contains("\u4e0d\u80fd\u5220\u9664\u5f53\u524d\u767b\u5f55\u7ba1\u7406\u5458"));
        verify(adminUserService).deleteAdminUser(11L, 11L);
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
}
