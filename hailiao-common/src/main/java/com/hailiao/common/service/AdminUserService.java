package com.hailiao.common.service;

import com.hailiao.common.entity.AdminUser;
import com.hailiao.common.repository.AdminUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import javax.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class AdminUserService {

    private static final int ROLE_SUPER_ADMIN = 1;

    @Autowired
    private AdminUserRepository adminUserRepository;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Transactional
    public AdminUser createAdminUser(AdminUser adminUser) {
        validateCreateRequest(adminUser);
        if (adminUserRepository.existsByUsername(adminUser.getUsername())) {
            throw new RuntimeException("\u7528\u6237\u540d\u5df2\u5b58\u5728");
        }

        normalizeAdminUser(adminUser);
        if (!StringUtils.hasText(adminUser.getPermissions())) {
            adminUser.setPermissions(String.join(",", getEffectivePermissions(adminUser.getRole(), null)));
        }
        adminUser.setPassword(passwordEncoder.encode(adminUser.getPassword()));
        adminUser.setStatus(1);
        adminUser.setCreatedAt(new Date());
        adminUser.setUpdatedAt(new Date());

        return adminUserRepository.save(adminUser);
    }

    public AdminUser login(String username, String password) {
        AdminUser adminUser = adminUserRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("\u7528\u6237\u4e0d\u5b58\u5728"));

        if (!passwordEncoder.matches(password, adminUser.getPassword())) {
            throw new RuntimeException("\u5bc6\u7801\u9519\u8bef");
        }

        if (adminUser.getStatus() == 0) {
            throw new RuntimeException("\u8d26\u53f7\u5df2\u88ab\u7981\u7528");
        }

        adminUser.setLastLoginAt(new Date());
        return adminUserRepository.save(adminUser);
    }

    public AdminUser getAdminUserById(Long id) {
        return adminUserRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("\u7ba1\u7406\u5458\u4e0d\u5b58\u5728"));
    }

    public List<AdminUser> getAllAdminUsers() {
        return adminUserRepository.findAll();
    }

    public Page<AdminUser> getAdminUserList(String keyword, Integer role, Integer status, Pageable pageable) {
        Specification<AdminUser> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (StringUtils.hasText(keyword)) {
                predicates.add(cb.or(
                        cb.like(root.get("username"), "%" + keyword + "%"),
                        cb.like(root.get("name"), "%" + keyword + "%")
                ));
            }

            if (role != null) {
                predicates.add(cb.equal(root.get("role"), role));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return adminUserRepository.findAll(spec, pageable);
    }

    public Map<String, Object> getAdminListSummary(String keyword, Integer role, Integer status) {
        Page<AdminUser> page = getAdminUserList(keyword, role, status, Pageable.unpaged());
        List<AdminUser> admins = page.getContent();

        LinkedHashMap<String, Object> summary = new LinkedHashMap<>();
        summary.put("filteredTotal", admins.size());

        long activeCount = admins.stream().filter(item -> item.getStatus() != null && item.getStatus() == 1).count();
        long disabledCount = admins.stream().filter(item -> item.getStatus() != null && item.getStatus() == 0).count();
        summary.put("activeCount", activeCount);
        summary.put("disabledCount", disabledCount);

        LinkedHashMap<String, Object> roleStats = new LinkedHashMap<>();
        for (Map<String, Object> roleTemplate : getRoleTemplates()) {
            Integer currentRole = (Integer) roleTemplate.get("role");
            long count = admins.stream()
                    .filter(item -> item.getRole() != null && item.getRole().equals(currentRole))
                    .count();

            LinkedHashMap<String, Object> item = new LinkedHashMap<>();
            item.put("role", currentRole);
            item.put("roleName", roleTemplate.get("roleName"));
            item.put("count", count);
            roleStats.put(String.valueOf(currentRole), item);
        }
        summary.put("roleStats", roleStats);
        summary.put("riskStats", buildRiskStats(admins));
        return summary;
    }

    @Transactional
    public AdminUser updateAdminUser(AdminUser adminUser) {
        return updateAdminUser(adminUser, null);
    }

    @Transactional
    public AdminUser updateAdminUser(AdminUser adminUser, Long currentAdminId) {
        validateUpdateRequest(adminUser);
        AdminUser existingUser = getAdminUserById(adminUser.getId());
        validateProtectedAdminChange(existingUser, adminUser.getRole(), adminUser.getStatus(), currentAdminId, false);

        if (adminUser.getName() != null) {
            existingUser.setName(adminUser.getName().trim());
        }
        if (adminUser.getRole() != null) {
            validateRole(adminUser.getRole());
            existingUser.setRole(adminUser.getRole());
            if (!StringUtils.hasText(adminUser.getPermissions())) {
                existingUser.setPermissions(String.join(",", getEffectivePermissions(adminUser.getRole(), null)));
            }
        }
        if (adminUser.getPermissions() != null) {
            existingUser.setPermissions(normalizePermissions(adminUser.getPermissions()));
        }
        if (adminUser.getStatus() != null) {
            validateStatus(adminUser.getStatus());
            existingUser.setStatus(adminUser.getStatus());
        }

        existingUser.setUpdatedAt(new Date());
        return adminUserRepository.save(existingUser);
    }

    @Transactional
    public AdminUser updateAdminPermissions(Long adminId, Integer role, String permissions) {
        return updateAdminPermissions(adminId, role, permissions, null);
    }

    @Transactional
    public AdminUser updateAdminPermissions(Long adminId, Integer role, String permissions, Long currentAdminId) {
        AdminUser existingUser = getAdminUserById(adminId);
        validateProtectedAdminChange(existingUser, role, null, currentAdminId, false);
        if (role != null) {
            validateRole(role);
            existingUser.setRole(role);
        }

        if (permissions != null) {
            existingUser.setPermissions(normalizePermissions(permissions));
        } else if (role != null) {
            existingUser.setPermissions(String.join(",", getEffectivePermissions(role, null)));
        }

        existingUser.setUpdatedAt(new Date());
        return adminUserRepository.save(existingUser);
    }

    @Transactional
    public void changePassword(Long adminId, String oldPassword, String newPassword) {
        validatePassword(newPassword, false);
        AdminUser adminUser = getAdminUserById(adminId);
        if (!passwordEncoder.matches(oldPassword, adminUser.getPassword())) {
            throw new RuntimeException("\u539f\u5bc6\u7801\u9519\u8bef");
        }
        adminUser.setPassword(passwordEncoder.encode(newPassword));
        adminUser.setUpdatedAt(new Date());
        adminUserRepository.save(adminUser);
    }

    @Transactional
    public AdminUser updateOwnProfile(Long adminId, String name) {
        AdminUser adminUser = getAdminUserById(adminId);
        if (name != null) {
            String normalizedName = name.trim();
            if (normalizedName.length() > 50) {
                throw new RuntimeException("\u6635\u79f0\u957f\u5ea6\u4e0d\u80fd\u8d85\u8fc7 50 \u4e2a\u5b57\u7b26");
            }
            adminUser.setName(normalizedName);
        }
        adminUser.setUpdatedAt(new Date());
        return adminUserRepository.save(adminUser);
    }

    @Transactional
    public void resetPassword(Long adminId, String newPassword) {
        validatePassword(newPassword, false);
        AdminUser adminUser = getAdminUserById(adminId);
        adminUser.setPassword(passwordEncoder.encode(newPassword));
        adminUser.setUpdatedAt(new Date());
        adminUserRepository.save(adminUser);
    }

    @Transactional
    public void deleteAdminUser(Long id) {
        deleteAdminUser(id, null);
    }

    @Transactional
    public void deleteAdminUser(Long id, Long currentAdminId) {
        AdminUser existingUser = getAdminUserById(id);
        validateProtectedAdminChange(existingUser, null, null, currentAdminId, true);
        adminUserRepository.deleteById(id);
    }

    public long getTotalAdminCount() {
        return adminUserRepository.count();
    }

    public Set<String> getEffectivePermissions(AdminUser adminUser) {
        if (adminUser == null) {
            return new LinkedHashSet<>();
        }
        return getEffectivePermissions(adminUser.getRole(), adminUser.getPermissions());
    }

    public Set<String> getEffectivePermissions(Integer role, String permissions) {
        LinkedHashSet<String> result = new LinkedHashSet<>();
        if (role != null && role == ROLE_SUPER_ADMIN) {
            result.add("*");
            return result;
        }

        if (StringUtils.hasText(permissions)) {
            String normalized = permissions.trim()
                    .replace("[", "")
                    .replace("]", "")
                    .replace("\"", "");
            Arrays.stream(normalized.split(","))
                    .map(String::trim)
                    .filter(StringUtils::hasText)
                    .forEach(result::add);
        }

        if (result.isEmpty()) {
            result.addAll(defaultPermissionsByRole(role));
        }
        return result;
    }

    public boolean hasPermission(AdminUser adminUser, String requiredPermission) {
        if (adminUser == null) {
            return false;
        }
        return hasPermission(adminUser.getRole(), adminUser.getPermissions(), requiredPermission);
    }

    public boolean hasPermission(Integer role, String permissions, String requiredPermission) {
        Set<String> effective = getEffectivePermissions(role, permissions);
        return effective.contains("*") || effective.contains(requiredPermission);
    }

    public List<String> getPermissionOptions() {
        return Arrays.asList(
                "dashboard:view",
                "statistics:view",
                "admin:manage",
                "user:manage",
                "group:manage",
                "message:monitor",
                "report:manage",
                "content-audit:manage",
                "order:manage",
                "vip:manage",
                "pretty-number:manage",
                "system-config:manage",
                "operation-log:view"
        );
    }

    public List<Map<String, Object>> getRoleTemplates() {
        List<Map<String, Object>> templates = new ArrayList<>();
        templates.add(buildRoleTemplate(1, getRoleName(1), getEffectivePermissions(1, null)));
        templates.add(buildRoleTemplate(2, getRoleName(2), getEffectivePermissions(2, null)));
        templates.add(buildRoleTemplate(3, getRoleName(3), getEffectivePermissions(3, null)));
        templates.add(buildRoleTemplate(4, getRoleName(4), getEffectivePermissions(4, null)));
        templates.add(buildRoleTemplate(5, getRoleName(5), getEffectivePermissions(5, null)));
        return templates;
    }

    public String getRoleName(Integer role) {
        if (role == null) {
            return "\u672a\u77e5\u89d2\u8272";
        }
        switch (role) {
            case 1:
                return "\u8d85\u7ea7\u7ba1\u7406\u5458";
            case 2:
                return "\u5ba1\u6838\u7ba1\u7406\u5458";
            case 3:
                return "\u5ba2\u670d\u7ba1\u7406\u5458";
            case 4:
                return "\u8d22\u52a1\u7ba1\u7406\u5458";
            case 5:
                return "\u8fd0\u8425\u7ba1\u7406\u5458";
            default:
                return "\u81ea\u5b9a\u4e49\u89d2\u8272";
        }
    }

    public String getRoleDescription(Integer role) {
        if (role == null) {
            return "\u672a\u77e5\u89d2\u8272\u6a21\u677f";
        }
        switch (role) {
            case 1:
                return "\u62e5\u6709\u6240\u6709\u540e\u53f0\u6a21\u5757\u548c\u6743\u9650\uff0c\u9002\u5408\u7cfb\u7edf\u8d1f\u8d23\u4eba";
            case 2:
                return "\u4e3b\u8981\u8d1f\u8d23\u4e3e\u62a5\u5ba1\u6838\u3001\u5185\u5bb9\u5ba1\u6838\u548c\u64cd\u4f5c\u65e5\u5fd7\u67e5\u770b";
            case 3:
                return "\u4e3b\u8981\u8d1f\u8d23\u7528\u6237\u3001\u7fa4\u7ec4\u3001\u6d88\u606f\u76d1\u63a7\u53ca\u4e3e\u62a5\u5904\u7406";
            case 4:
                return "\u4e3b\u8981\u8d1f\u8d23\u8ba2\u5355\u3001VIP \u548c\u9753\u53f7\u7b49\u5546\u4e1a\u5316\u80fd\u529b";
            case 5:
                return "\u4e3b\u8981\u8d1f\u8d23\u8fd0\u8425\u914d\u7f6e\u3001\u7edf\u8ba1\u548c\u90e8\u5206\u7528\u6237/\u7fa4\u7ec4\u7ba1\u7406";
            default:
                return "\u81ea\u5b9a\u4e49\u89d2\u8272\u8bf4\u660e";
        }
    }

    public Map<String, Object> getAdminStatsSummary() {
        List<AdminUser> admins = adminUserRepository.findAll();
        LinkedHashMap<String, Object> stats = new LinkedHashMap<>();
        stats.put("totalAdmins", admins.size());
        stats.put("activeAdmins", admins.stream().filter(item -> item.getStatus() != null && item.getStatus() == 1).count());
        stats.put("disabledAdmins", admins.stream().filter(item -> item.getStatus() != null && item.getStatus() == 0).count());

        LinkedHashMap<String, Object> roleStats = new LinkedHashMap<>();
        for (Map<String, Object> roleTemplate : getRoleTemplates()) {
            Integer role = (Integer) roleTemplate.get("role");
            LinkedHashMap<String, Object> item = new LinkedHashMap<>();
            item.put("role", role);
            item.put("roleName", roleTemplate.get("roleName"));
            item.put("count", admins.stream().filter(admin -> admin.getRole() != null && admin.getRole().equals(role)).count());
            roleStats.put(String.valueOf(role), item);
        }
        stats.put("roleStats", roleStats);
        stats.put("riskStats", buildRiskStats(admins));
        return stats;
    }

    public Map<String, Object> toAdminResponse(AdminUser adminUser) {
        Set<String> effectivePermissions = getEffectivePermissions(adminUser);
        String permissionRiskLevel = getPermissionRiskLevel(effectivePermissions);
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", adminUser.getId());
        item.put("username", adminUser.getUsername());
        item.put("name", adminUser.getName());
        item.put("role", adminUser.getRole());
        item.put("roleName", getRoleName(adminUser.getRole()));
        item.put("roleDescription", getRoleDescription(adminUser.getRole()));
        item.put("permissions", adminUser.getPermissions());
        item.put("permissionSummary", summarizePermissions(adminUser.getPermissions()));
        item.put("effectivePermissions", effectivePermissions);
        item.put("effectivePermissionCount", effectivePermissions.size());
        item.put("hasWildcardPermission", effectivePermissions.contains("*"));
        item.put("permissionRiskLevel", permissionRiskLevel);
        item.put("permissionRiskLabel", getPermissionRiskLabel(permissionRiskLevel));
        item.put("status", adminUser.getStatus());
        item.put("statusLabel", adminUser.getStatus() != null && adminUser.getStatus() == 1 ? "\u542f\u7528" : "\u7981\u7528");
        item.put("lastLoginAt", adminUser.getLastLoginAt());
        item.put("lastLoginIp", adminUser.getLastLoginIp());
        item.put("createdAt", adminUser.getCreatedAt());
        item.put("updatedAt", adminUser.getUpdatedAt());
        return item;
    }

    public Map<String, Object> buildAdminContext(AdminUser adminUser) {
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("admin", toAdminResponse(adminUser));
        context.put("permissionOptions", getPermissionOptions());
        context.put("roleOptions", getRoleTemplates());
        return context;
    }

    private void validateCreateRequest(AdminUser adminUser) {
        if (adminUser == null) {
            throw new RuntimeException("\u7ba1\u7406\u5458\u53c2\u6570\u4e0d\u80fd\u4e3a\u7a7a");
        }
        validateUsername(adminUser.getUsername());
        validatePassword(adminUser.getPassword(), true);
        validateRole(adminUser.getRole());
        if (adminUser.getStatus() != null) {
            validateStatus(adminUser.getStatus());
        }
    }

    private void validateUpdateRequest(AdminUser adminUser) {
        if (adminUser == null || adminUser.getId() == null) {
            throw new RuntimeException("\u7ba1\u7406\u5458 ID \u4e0d\u80fd\u4e3a\u7a7a");
        }
        if (adminUser.getRole() != null) {
            validateRole(adminUser.getRole());
        }
        if (adminUser.getStatus() != null) {
            validateStatus(adminUser.getStatus());
        }
        if (adminUser.getName() != null && adminUser.getName().trim().length() > 50) {
            throw new RuntimeException("\u6635\u79f0\u957f\u5ea6\u4e0d\u80fd\u8d85\u8fc7 50 \u4e2a\u5b57\u7b26");
        }
    }

    private void normalizeAdminUser(AdminUser adminUser) {
        adminUser.setUsername(adminUser.getUsername().trim());
        if (adminUser.getName() != null) {
            adminUser.setName(adminUser.getName().trim());
        }
        if (adminUser.getPermissions() != null) {
            adminUser.setPermissions(normalizePermissions(adminUser.getPermissions()));
        }
    }

    private String normalizePermissions(String permissions) {
        String normalized = permissions == null ? null : permissions.trim();
        if (!StringUtils.hasText(normalized)) {
            return normalized;
        }
        normalized = normalized.replace("[", "").replace("]", "").replace("\"", "");
        LinkedHashSet<String> values = new LinkedHashSet<>();
        Arrays.stream(normalized.split(","))
                .map(String::trim)
                .filter(StringUtils::hasText)
                .forEach(values::add);
        return String.join(",", values);
    }

    private String summarizePermissions(String permissions) {
        if (!StringUtils.hasText(permissions)) {
            return "";
        }
        String normalized = normalizePermissions(permissions);
        if (!StringUtils.hasText(normalized)) {
            return "";
        }
        if (normalized.length() > 80) {
            return normalized.substring(0, 80) + "...";
        }
        return normalized;
    }

    private String getPermissionRiskLevel(Set<String> effectivePermissions) {
        if (effectivePermissions == null || effectivePermissions.isEmpty()) {
            return "low";
        }
        if (effectivePermissions.contains("*")) {
            return "critical";
        }
        if (effectivePermissions.contains("admin:manage")
                || effectivePermissions.contains("system-config:manage")
                || effectivePermissions.size() >= 8) {
            return "high";
        }
        if (effectivePermissions.contains("operation-log:view")
                || effectivePermissions.contains("content-audit:manage")
                || effectivePermissions.contains("message:monitor")
                || effectivePermissions.size() >= 4) {
            return "medium";
        }
        return "low";
    }

    private String getPermissionRiskLabel(String riskLevel) {
        if (!StringUtils.hasText(riskLevel)) {
            return "\u4f4e\u98ce\u9669";
        }
        switch (riskLevel) {
            case "critical":
                return "\u6781\u9ad8\u98ce\u9669";
            case "high":
                return "\u9ad8\u98ce\u9669";
            case "medium":
                return "\u4e2d\u98ce\u9669";
            default:
                return "\u4f4e\u98ce\u9669";
        }
    }

    private Map<String, Object> buildRiskStats(List<AdminUser> admins) {
        LinkedHashMap<String, Object> riskStats = new LinkedHashMap<>();
        riskStats.put("critical", buildRiskStatItem("critical", getPermissionRiskLabel("critical"), admins));
        riskStats.put("high", buildRiskStatItem("high", getPermissionRiskLabel("high"), admins));
        riskStats.put("medium", buildRiskStatItem("medium", getPermissionRiskLabel("medium"), admins));
        riskStats.put("low", buildRiskStatItem("low", getPermissionRiskLabel("low"), admins));
        return riskStats;
    }

    private Map<String, Object> buildRiskStatItem(String riskLevel, String riskLabel, List<AdminUser> admins) {
        long count = admins.stream()
                .filter(admin -> riskLevel.equals(getPermissionRiskLevel(getEffectivePermissions(admin))))
                .count();
        LinkedHashMap<String, Object> item = new LinkedHashMap<>();
        item.put("riskLevel", riskLevel);
        item.put("riskLabel", riskLabel);
        item.put("count", count);
        return item;
    }

    private void validateUsername(String username) {
        if (!StringUtils.hasText(username)) {
            throw new RuntimeException("\u7528\u6237\u540d\u4e0d\u80fd\u4e3a\u7a7a");
        }
        String normalized = username.trim();
        if (normalized.length() < 3 || normalized.length() > 50) {
            throw new RuntimeException("\u7528\u6237\u540d\u957f\u5ea6\u5fc5\u987b\u5728 3 \u5230 50 \u4e2a\u5b57\u7b26\u4e4b\u95f4");
        }
    }

    private void validatePassword(String password, boolean required) {
        if (!StringUtils.hasText(password)) {
            if (required) {
                throw new RuntimeException("\u5bc6\u7801\u4e0d\u80fd\u4e3a\u7a7a");
            }
            return;
        }
        if (password.trim().length() < 6 || password.trim().length() > 100) {
            throw new RuntimeException("\u5bc6\u7801\u957f\u5ea6\u5fc5\u987b\u5728 6 \u5230 100 \u4e2a\u5b57\u7b26\u4e4b\u95f4");
        }
    }

    private void validateRole(Integer role) {
        if (role == null || role < 1 || role > 5) {
            throw new RuntimeException("\u89d2\u8272\u503c\u4e0d\u5408\u6cd5");
        }
    }

    private void validateStatus(Integer status) {
        if (status == null || (status != 0 && status != 1)) {
            throw new RuntimeException("\u72b6\u6001\u503c\u4e0d\u5408\u6cd5");
        }
    }

    private void validateProtectedAdminChange(
            AdminUser existingUser,
            Integer newRole,
            Integer newStatus,
            Long currentAdminId,
            boolean deleting) {
        if (currentAdminId != null && existingUser.getId().equals(currentAdminId)) {
            if (deleting) {
                throw new RuntimeException("\u4e0d\u80fd\u5220\u9664\u5f53\u524d\u767b\u5f55\u7ba1\u7406\u5458");
            }
            if (newStatus != null && newStatus == 0) {
                throw new RuntimeException("\u4e0d\u80fd\u7981\u7528\u5f53\u524d\u767b\u5f55\u7ba1\u7406\u5458");
            }
        }

        boolean isSuperAdmin = existingUser.getRole() != null && existingUser.getRole() == ROLE_SUPER_ADMIN;
        if (!isSuperAdmin) {
            return;
        }

        boolean roleChangedAwayFromSuperAdmin = newRole != null && newRole != ROLE_SUPER_ADMIN;
        boolean disabled = newStatus != null && newStatus == 0;
        if (deleting || roleChangedAwayFromSuperAdmin || disabled) {
            long superAdminCount = adminUserRepository.countByRole(ROLE_SUPER_ADMIN);
            if (superAdminCount <= 1) {
                throw new RuntimeException("\u81f3\u5c11\u9700\u4fdd\u7559\u4e00\u4e2a\u8d85\u7ea7\u7ba1\u7406\u5458");
            }
        }
    }

    private Map<String, Object> buildRoleTemplate(Integer role, String roleName, Set<String> permissions) {
        LinkedHashMap<String, Object> item = new LinkedHashMap<>();
        item.put("role", role);
        item.put("roleName", roleName);
        item.put("description", getRoleDescription(role));
        item.put("permissions", permissions);
        return item;
    }

    private Set<String> defaultPermissionsByRole(Integer role) {
        LinkedHashSet<String> defaults = new LinkedHashSet<>();
        if (role == null) {
            return defaults;
        }
        switch (role) {
            case 2:
                defaults.add("dashboard:view");
                defaults.add("report:manage");
                defaults.add("content-audit:manage");
                defaults.add("operation-log:view");
                break;
            case 3:
                defaults.add("dashboard:view");
                defaults.add("user:manage");
                defaults.add("group:manage");
                defaults.add("message:monitor");
                defaults.add("report:manage");
                break;
            case 4:
                defaults.add("dashboard:view");
                defaults.add("order:manage");
                defaults.add("pretty-number:manage");
                defaults.add("vip:manage");
                break;
            case 5:
                defaults.add("dashboard:view");
                defaults.add("user:manage");
                defaults.add("group:manage");
                defaults.add("system-config:manage");
                defaults.add("vip:manage");
                defaults.add("pretty-number:manage");
                defaults.add("statistics:view");
                defaults.add("operation-log:view");
                break;
            default:
                break;
        }
        return defaults;
    }
}
