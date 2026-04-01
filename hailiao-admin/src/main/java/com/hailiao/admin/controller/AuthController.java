package com.hailiao.admin.controller;

import com.hailiao.common.entity.AdminUser;
import com.hailiao.common.service.AdminUserService;
import com.hailiao.common.util.AdminJwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 后台管理员认证控制器。
 */
@RestController
@RequestMapping("/admin/auth")
public class AuthController {

    @Autowired
    private AdminUserService adminUserService;

    @Autowired
    private AdminJwtUtil jwtUtil;

    /**
     * 管理员登录。
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> request) {
        try {
            String username = request.get("username");
            String password = request.get("password");

            if (username == null || password == null) {
                return ResponseEntity.badRequest().body("\u7528\u6237\u540d\u548c\u5bc6\u7801\u4e0d\u80fd\u4e3a\u7a7a");
            }

            AdminUser adminUser = adminUserService.login(username, password);
            String token = jwtUtil.generateToken(adminUser.getId(), adminUser.getUsername(), 2);

            Map<String, Object> response = adminUserService.buildAdminContext(adminUser);
            response.put("token", token);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(e.getMessage());
        }
    }

    /**
     * 获取当前管理员信息。
     */
    @GetMapping("/me")
    public ResponseEntity<?> getCurrentAdmin(@RequestAttribute("adminId") Long adminId) {
        try {
            AdminUser adminUser = adminUserService.getAdminUserById(adminId);
            return ResponseEntity.ok(adminUserService.toAdminResponse(adminUser));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 获取当前管理员上下文。
     */
    @GetMapping("/context")
    public ResponseEntity<?> getCurrentAdminContext(@RequestAttribute("adminId") Long adminId) {
        try {
            AdminUser adminUser = adminUserService.getAdminUserById(adminId);
            return ResponseEntity.ok(adminUserService.buildAdminContext(adminUser));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 更新当前管理员资料。
     */
    @PutMapping("/profile")
    public ResponseEntity<?> updateCurrentAdminProfile(
            @RequestAttribute("adminId") Long adminId,
            @RequestBody Map<String, String> request) {
        try {
            AdminUser adminUser = adminUserService.updateOwnProfile(adminId, request.get("name"));
            return ResponseEntity.ok(adminUserService.buildAdminContext(adminUser));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 修改当前管理员密码。
     */
    @PostMapping("/change-password")
    public ResponseEntity<?> changeCurrentAdminPassword(
            @RequestAttribute("adminId") Long adminId,
            @RequestBody Map<String, String> request) {
        try {
            String oldPassword = request.get("oldPassword");
            String newPassword = request.get("newPassword");
            if (oldPassword == null || newPassword == null) {
                return ResponseEntity.badRequest().body("\u539f\u5bc6\u7801\u548c\u65b0\u5bc6\u7801\u4e0d\u80fd\u4e3a\u7a7a");
            }

            adminUserService.changePassword(adminId, oldPassword, newPassword);
            Map<String, Object> response = new java.util.LinkedHashMap<>();
            response.put("message", "\u5bc6\u7801\u4fee\u6539\u6210\u529f");
            response.put("requireLoginRefresh", true);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 刷新管理员 token。
     */
    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(
            @RequestAttribute("adminId") Long adminId,
            @RequestAttribute("username") String username) {
        try {
            String newToken = jwtUtil.generateToken(adminId, username, 2);
            return ResponseEntity.ok(newToken);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
