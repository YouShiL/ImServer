package com.hailiao.admin.controller;

import com.hailiao.common.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 用户管理兼容控制器。
 * 保留旧路由 `/admin/users`，内部复用 `/admin/user` 主路由逻辑。
 */
@Deprecated
@RestController
@RequestMapping("/admin/users")
public class UserManagementController {

    @Autowired
    private UserService userService;

    @Autowired
    private UserManageController userManageController;

    /**
     * 兼容旧版用户列表接口。
     */
    @GetMapping
    public ResponseEntity<?> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String keyword) {
        return userManageController.getUserList(keyword, null, page, size);
    }

    /**
     * 兼容旧版用户详情接口。
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getUserById(@PathVariable Long id) {
        return userManageController.getUserById(id);
    }

    /**
     * 兼容旧版用户状态更新接口。
     */
    @PutMapping("/{id}/status")
    public ResponseEntity<?> updateUserStatus(@PathVariable Long id, @RequestParam Integer status) {
        try {
            if (status != null && status == 0) {
                userService.banUser(id, null);
            } else {
                userService.unbanUser(id);
            }
            return userManageController.getUserById(id);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * 兼容旧版用户更新接口。
     */
    @PutMapping("/{id}")
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody com.hailiao.common.entity.User userData) {
        return userManageController.updateUser(id, userData);
    }

    /**
     * 删除用户。
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        try {
            userService.deleteUser(id);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}
