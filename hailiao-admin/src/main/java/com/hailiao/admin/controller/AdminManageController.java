package com.hailiao.admin.controller;

import com.hailiao.common.entity.AdminUser;
import com.hailiao.common.service.AdminUserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 鍚庡彴绠＄悊鍛樼鐞嗘帶鍒跺櫒銆? */
@RestController
@RequestMapping("/admin/admin")
public class AdminManageController {

    @Autowired
    private AdminUserService adminUserService;

    /**
     * 鍒嗛〉鑾峰彇绠＄悊鍛樺垪琛ㄣ€?     */
    @GetMapping("/list")
    public ResponseEntity<?> getAdminList(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer role,
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<AdminUser> admins = adminUserService.getAdminUserList(keyword, role, status, pageable);
            Map<String, Object> summary = adminUserService.getAdminListSummary(keyword, role, status);
            return ResponseEntity.ok(toPageResponse(admins, summary));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 鑾峰彇鍏ㄩ儴绠＄悊鍛樸€?     */
    @GetMapping("/all")
    public ResponseEntity<?> getAllAdmins() {
        try {
            List<Map<String, Object>> items = new ArrayList<>();
            for (AdminUser adminUser : adminUserService.getAllAdminUsers()) {
                items.add(adminUserService.toAdminResponse(adminUser));
            }
            return ResponseEntity.ok(items);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 瀵煎嚭绠＄悊鍛樺垪琛ㄣ€?     */
    @GetMapping("/export")
    public ResponseEntity<?> exportAdmins(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer role,
            @RequestParam(required = false) Integer status) {
        try {
            Page<AdminUser> admins = adminUserService.getAdminUserList(keyword, role, status, Pageable.unpaged());
            String csv = buildAdminCsv(admins.getContent());

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("text/csv; charset=UTF-8"));
            headers.set(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=admin-list.csv");
            return ResponseEntity.ok().headers(headers).body(csv);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 鏍规嵁 ID 鑾峰彇绠＄悊鍛樿鎯呫€?     */
    @GetMapping("/{adminId}")
    public ResponseEntity<?> getAdminById(@PathVariable Long adminId) {
        try {
            AdminUser admin = adminUserService.getAdminUserById(adminId);
            return ResponseEntity.ok(adminUserService.toAdminResponse(admin));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 鍒涘缓绠＄悊鍛樸€?     */
    @PostMapping
    public ResponseEntity<?> createAdmin(@RequestBody AdminUser adminUser, HttpServletRequest request) {
        try {
            AdminUser createdAdmin = adminUserService.createAdminUser(adminUser);
            attachAdminLogContext(request, createdAdmin, createdAdmin.getPermissions());
            return ResponseEntity.ok(adminUserService.toAdminResponse(createdAdmin));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 鏇存柊绠＄悊鍛樹俊鎭€?     */
    @PutMapping("/{adminId}")
    public ResponseEntity<?> updateAdmin(
            @PathVariable Long adminId,
            @RequestBody AdminUser adminUser,
            @RequestAttribute("adminId") Long currentAdminId,
            HttpServletRequest request) {
        try {
            adminUser.setId(adminId);
            AdminUser updatedAdmin = adminUserService.updateAdminUser(adminUser, currentAdminId);
            attachAdminLogContext(request, updatedAdmin, updatedAdmin.getPermissions());
            return ResponseEntity.ok(adminUserService.toAdminResponse(updatedAdmin));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 鏇存柊绠＄悊鍛樿鑹插拰鏉冮檺锛屽苟杩斿洖鏄惁褰卞搷褰撳墠鐧诲綍浼氳瘽銆?     */
    @PutMapping("/{adminId}/permissions")
    public ResponseEntity<?> updateAdminPermissions(
            @PathVariable Long adminId,
            @RequestBody Map<String, Object> request,
            @RequestAttribute("adminId") Long currentAdminId,
            HttpServletRequest servletRequest) {
        try {
            Integer role = request.get("role") == null ? null : Integer.valueOf(request.get("role").toString());
            String permissions = request.get("permissions") == null ? null : request.get("permissions").toString();

            AdminUser updatedAdmin = adminUserService.updateAdminPermissions(adminId, role, permissions, currentAdminId);
            attachAdminLogContext(servletRequest, updatedAdmin, permissions == null ? updatedAdmin.getPermissions() : permissions);
            boolean affectsCurrentAdminSession = currentAdminId != null && currentAdminId.equals(adminId);

            Map<String, Object> response = new LinkedHashMap<>();
            response.put("admin", adminUserService.toAdminResponse(updatedAdmin));
            response.put("affectsCurrentAdminSession", affectsCurrentAdminSession);
            if (affectsCurrentAdminSession) {
                response.put("currentAdminContext", adminUserService.buildAdminContext(updatedAdmin));
            }
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 鍒犻櫎绠＄悊鍛樸€?     */
    @DeleteMapping("/{adminId}")
    public ResponseEntity<?> deleteAdmin(
            @PathVariable Long adminId,
            @RequestAttribute("adminId") Long currentAdminId,
            HttpServletRequest request) {
        try {
            AdminUser targetAdmin = adminUserService.getAdminUserById(adminId);
            attachAdminLogContext(request, targetAdmin, targetAdmin.getPermissions());
            adminUserService.deleteAdminUser(adminId, currentAdminId);
            return ResponseEntity.ok("\u5220\u9664\u6210\u529f");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 閲嶇疆绠＄悊鍛樺瘑鐮併€?     */
    @PostMapping("/{adminId}/reset-password")
    public ResponseEntity<?> resetPassword(
            @PathVariable Long adminId,
            @RequestBody Map<String, String> request,
            HttpServletRequest servletRequest) {
        try {
            String newPassword = request.get("newPassword");
            AdminUser targetAdmin = adminUserService.getAdminUserById(adminId);
            attachAdminLogContext(servletRequest, targetAdmin, null);
            adminUserService.resetPassword(adminId, newPassword);
            return ResponseEntity.ok("\u5bc6\u7801\u91cd\u7f6e\u6210\u529f");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 鑾峰彇绠＄悊鍛樼粺璁′俊鎭€?     */
    @GetMapping("/stats")
    public ResponseEntity<?> getAdminStats() {
        try {
            return ResponseEntity.ok(adminUserService.getAdminStatsSummary());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 棰勮瑙掕壊鍜屾潈闄愰厤缃殑鏈€缁堢敓鏁堢粨鏋溿€?     */
    @PostMapping("/permission-preview")
    public ResponseEntity<?> previewPermissions(@RequestBody Map<String, Object> request) {
        try {
            Integer role = request.get("role") == null ? null : Integer.valueOf(request.get("role").toString());
            String permissions = request.get("permissions") == null ? null : request.get("permissions").toString();

            Map<String, Object> preview = new LinkedHashMap<>();
            preview.put("role", role);
            preview.put("roleName", adminUserService.getRoleName(role));
            preview.put("permissions", permissions);
            preview.put("effectivePermissions", adminUserService.getEffectivePermissions(role, permissions));
            return ResponseEntity.ok(preview);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 鑾峰彇鍚庡彴鍙€夋潈闄愬垪琛ㄣ€?     */
    @GetMapping("/permission-options")
    public ResponseEntity<?> getPermissionOptions() {
        try {
            return ResponseEntity.ok(adminUserService.getPermissionOptions());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 鑾峰彇鍚庡彴瑙掕壊妯℃澘鍒楄〃銆?     */
    @GetMapping("/role-options")
    public ResponseEntity<?> getRoleOptions() {
        try {
            return ResponseEntity.ok(adminUserService.getRoleTemplates());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    private Map<String, Object> toPageResponse(Page<AdminUser> admins, Map<String, Object> summary) {
        List<Map<String, Object>> content = new ArrayList<>();
        for (AdminUser adminUser : admins.getContent()) {
            content.add(adminUserService.toAdminResponse(adminUser));
        }

        Map<String, Object> page = new LinkedHashMap<>();
        page.put("content", content);
        page.put("page", admins.getNumber());
        page.put("size", admins.getSize());
        page.put("totalElements", admins.getTotalElements());
        page.put("totalPages", admins.getTotalPages());
        page.put("first", admins.isFirst());
        page.put("last", admins.isLast());
        if (summary != null) {
            page.put("summary", summary);
        }
        return page;
    }

        private String buildAdminCsv(List<AdminUser> admins) {
        StringBuilder builder = new StringBuilder();
        builder.append(csvRow(
                "ID",
                "\u7528\u6237\u540d",
                "\u6635\u79f0",
                "\u89d2\u8272",
                "\u72b6\u6001",
                "\u6743\u9650\u6458\u8981",
                "\u6709\u6548\u6743\u9650\u6570",
                "\u6700\u540e\u767b\u5f55\u65f6\u95f4",
                "\u6700\u540e\u767b\u5f55IP",
                "\u521b\u5efa\u65f6\u95f4"
        ));
        for (AdminUser adminUser : admins) {
            Set<String> effectivePermissions = adminUserService.getEffectivePermissions(adminUser);
            builder.append(csvRow(
                    valueOf(adminUser.getId()),
                    adminUser.getUsername(),
                    adminUser.getName(),
                    adminUserService.getRoleName(adminUser.getRole()),
                    adminUser.getStatus() != null && adminUser.getStatus() == 1 ? "\u542f\u7528" : "\u7981\u7528",
                    summarizePermissions(adminUser.getPermissions()),
                    valueOf(effectivePermissions.size()),
                    formatDate(adminUser.getLastLoginAt()),
                    adminUser.getLastLoginIp(),
                    formatDate(adminUser.getCreatedAt())
            ));
        }
        return builder.toString();
    }

    private String summarizePermissions(String permissions) {
        if (permissions == null || permissions.trim().isEmpty()) {
            return "";
        }
        String normalized = permissions.trim();
        if (normalized.length() > 80) {
            return normalized.substring(0, 80) + "...";
        }
        return normalized;
    }

    private String csvRow(String... values) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < values.length; i++) {
            if (i > 0) {
                builder.append(",");
            }
            builder.append("\"").append(escapeCsv(values[i])).append("\"");
        }
        builder.append("\r\n");
        return builder.toString();
    }

    private String escapeCsv(String value) {
        return value == null ? "" : value.replace("\"", "\"\"");
    }

    private String formatDate(Date date) {
        if (date == null) {
            return "";
        }
        return new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(date);
    }

    private String valueOf(Object value) {
        return value == null ? "" : String.valueOf(value);
    }

    private void attachAdminLogContext(HttpServletRequest request, AdminUser adminUser, String permissions) {
        if (request == null || adminUser == null) {
            return;
        }
        request.setAttribute("targetAdminId", adminUser.getId());
        request.setAttribute("targetAdminUsername", adminUser.getUsername());
        request.setAttribute("targetAdminRoleName", adminUserService.getRoleName(adminUser.getRole()));
        if (permissions != null) {
            request.setAttribute("targetPermissionSummary", summarizePermissions(permissions));
        }
    }
}
