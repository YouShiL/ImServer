package com.hailiao.common.service;

import com.hailiao.common.entity.AdminUser;
import com.hailiao.common.repository.AdminUserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.Map;
import java.util.Optional;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminUserServiceTest {

    @Mock
    private AdminUserRepository adminUserRepository;

    @InjectMocks
    private AdminUserService adminUserService;

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @Test
    void createAdminUserShouldApplyDefaultsAndEncodePassword() {
        AdminUser adminUser = new AdminUser();
        adminUser.setUsername("admin");
        adminUser.setPassword("123456");
        adminUser.setName("manager");
        adminUser.setRole(3);

        when(adminUserRepository.existsByUsername("admin")).thenReturn(false);
        when(adminUserRepository.save(any(AdminUser.class))).thenAnswer(new org.mockito.stubbing.Answer<AdminUser>() {
            @Override
            public AdminUser answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (AdminUser) invocation.getArgument(0);
            }
        });

        AdminUser saved = adminUserService.createAdminUser(adminUser);

        assertEquals(Integer.valueOf(1), saved.getStatus());
        assertTrue(encoder.matches("123456", saved.getPassword()));
        assertTrue(saved.getPermissions().contains("user:manage"));
        assertTrue(saved.getPermissions().contains("group:manage"));
    }

    @Test
    void loginShouldRejectDisabledAccount() {
        AdminUser adminUser = new AdminUser();
        adminUser.setId(1L);
        adminUser.setUsername("admin");
        adminUser.setPassword(encoder.encode("123456"));
        adminUser.setStatus(0);

        when(adminUserRepository.findByUsername("admin")).thenReturn(Optional.of(adminUser));

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        adminUserService.login("admin", "123456");
                    }
                });

        assertEquals("\u8d26\u53f7\u5df2\u88ab\u7981\u7528", error.getMessage());
    }

    @Test
    void updateAdminPermissionsShouldFallbackToRoleDefaults() {
        AdminUser existing = new AdminUser();
        existing.setId(2L);
        existing.setRole(3);
        existing.setPermissions("user:manage");
        existing.setStatus(1);

        when(adminUserRepository.findById(2L)).thenReturn(Optional.of(existing));
        when(adminUserRepository.save(any(AdminUser.class))).thenAnswer(new org.mockito.stubbing.Answer<AdminUser>() {
            @Override
            public AdminUser answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (AdminUser) invocation.getArgument(0);
            }
        });

        AdminUser saved = adminUserService.updateAdminPermissions(2L, 5, null, 1L);

        assertEquals(Integer.valueOf(5), saved.getRole());
        assertTrue(saved.getPermissions().contains("statistics:view"));
        assertTrue(saved.getPermissions().contains("system-config:manage"));
    }

    @Test
    void deleteAdminUserShouldProtectLastSuperAdmin() {
        AdminUser existing = new AdminUser();
        existing.setId(1L);
        existing.setRole(1);
        existing.setStatus(1);

        when(adminUserRepository.findById(1L)).thenReturn(Optional.of(existing));
        when(adminUserRepository.countByRole(1)).thenReturn(1L);

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        adminUserService.deleteAdminUser(1L, 2L);
                    }
                });

        assertEquals("\u81f3\u5c11\u9700\u4fdd\u7559\u4e00\u4e2a\u8d85\u7ea7\u7ba1\u7406\u5458", error.getMessage());
    }

    @Test
    void updateAdminUserShouldRejectDisablingCurrentAdmin() {
        AdminUser existing = new AdminUser();
        existing.setId(2L);
        existing.setRole(3);
        existing.setStatus(1);

        AdminUser request = new AdminUser();
        request.setId(2L);
        request.setStatus(0);

        when(adminUserRepository.findById(2L)).thenReturn(Optional.of(existing));

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        adminUserService.updateAdminUser(request, 2L);
                    }
                });

        assertEquals("\u4e0d\u80fd\u7981\u7528\u5f53\u524d\u767b\u5f55\u7ba1\u7406\u5458", error.getMessage());
    }

    @Test
    void toAdminResponseShouldIncludeRiskAndLabels() {
        AdminUser adminUser = new AdminUser();
        adminUser.setId(9L);
        adminUser.setUsername("ops");
        adminUser.setName("Operations");
        adminUser.setRole(5);
        adminUser.setPermissions("dashboard:view,system-config:manage,statistics:view");
        adminUser.setStatus(1);

        Map<String, Object> response = adminUserService.toAdminResponse(adminUser);

        assertEquals("\u8fd0\u8425\u7ba1\u7406\u5458", response.get("roleName"));
        assertEquals("\u542f\u7528", response.get("statusLabel"));
        assertEquals("high", response.get("permissionRiskLevel"));
        assertEquals("\u9ad8\u98ce\u9669", response.get("permissionRiskLabel"));
        assertFalse((Boolean) response.get("hasWildcardPermission"));
        assertTrue((Integer) response.get("effectivePermissionCount") >= 3);
    }

    @Test
    void getEffectivePermissionsShouldReturnWildcardForSuperAdmin() {
        Set<String> permissions = adminUserService.getEffectivePermissions(1, null);

        assertEquals(1, permissions.size());
        assertTrue(permissions.contains("*"));
    }
}
