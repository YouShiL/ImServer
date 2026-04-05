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
            throw new RuntimeException("用户名已存在");
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
                .orElseThrow(() -> new RuntimeException("用户不存在"));

        if (!passwordEncoder.matches(password, adminUser.getPassword())) {
            throw new RuntimeException("密码错误");
        }

        if (adminUser.getStatus() == 0) {
            throw new RuntimeException("账号已被禁用");
        }

        adminUser.setLastLoginAt(new Date());
        return adminUserRepository.save(adminUser);
    }

    public AdminUser getAdminUserById(Long id) {
        return adminUserRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("管理员不存在"));
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
            throw new RuntimeException("原密码错误");
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
                throw new RuntimeException("昵称长度不能超过 50 个字符");
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
            return "未知角色";
        }
        switch (role) {
            case 1:
                return "超级管理员";
            case 2:
                return "审核管理员";
            case 3:
                return "客服管理员";
            case 4:
                return "财务管理员";
            case 5:
                return "运营管理员";
            default:
                return "自定义角色";
        }
    }

    public String getRoleDescription(Integer role) {
        if (role == null) {
            return "未知角色模板";
        }
        switch (role) {
            case 1:
                return "拥有所有后台模块和权限，适合系统负责人";
            case 2:
                return "主要负责举报审核、内容审核和操作日志查看";
            case 3:
                return "主要负责用户、群组、消息监控及举报处理";
            case 4:
                return "主要负责订单、VIP 和靓号等商业化能力";
            case 5:
                return "主要负责运营配置、统计和部分用户/群组管理";
            default:
                return "自定义角色说明";
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
        item.put("statusLabel", adminUser.getStatus() != null && adminUser.getStatus() == 1 ? "启用" : "禁用");
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
            throw new RuntimeException("管理员参数不能为空");
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
            throw new RuntimeException("管理员 ID 不能为空");
        }
        if (adminUser.getRole() != null) {
            validateRole(adminUser.getRole());
        }
        if (adminUser.getStatus() != null) {
            validateStatus(adminUser.getStatus());
        }
        if (adminUser.getName() != null && adminUser.getName().trim().length() > 50) {
            throw new RuntimeException("昵称长度不能超过 50 个字符");
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
            return "低风险";
        }
        switch (riskLevel) {
            case "critical":
                return "极高风险";
            case "high":
                return "高风险";
            case "medium":
                return "中风险";
            default:
                return "低风险";
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
            throw new RuntimeException("用户名不能为空");
        }
        String normalized = username.trim();
        if (normalized.length() < 3 || normalized.length() > 50) {
            throw new RuntimeException("用户名长度必须在 3 到 50 个字符之间");
        }
    }

    private void validatePassword(String password, boolean required) {
        if (!StringUtils.hasText(password)) {
            if (required) {
                throw new RuntimeException("密码不能为空");
            }
            return;
        }
        if (password.trim().length() < 6 || password.trim().length() > 100) {
            throw new RuntimeException("密码长度必须在 6 到 100 个字符之间");
        }
    }

    private void validateRole(Integer role) {
        if (role == null || role < 1 || role > 5) {
            throw new RuntimeException("角色值不合法");
        }
    }

    private void validateStatus(Integer status) {
        if (status == null || (status != 0 && status != 1)) {
            throw new RuntimeException("状态值不合法");
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
                throw new RuntimeException("不能删除当前登录管理员");
            }
            if (newStatus != null && newStatus == 0) {
                throw new RuntimeException("不能禁用当前登录管理员");
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
                throw new RuntimeException("至少需保留一个超级管理员");
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
