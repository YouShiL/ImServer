package com.hailiao.admin.interceptor;

import com.alibaba.fastjson2.JSON;
import com.hailiao.common.service.AdminUserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class AdminPermissionInterceptor implements HandlerInterceptor {

    @Autowired
    private AdminUserService adminUserService;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String requiredPermission = resolveRequiredPermission(request.getRequestURI());
        if (requiredPermission == null) {
            return true;
        }

        Integer role = parseInteger(request.getAttribute("adminRole"));
        String permissions = request.getAttribute("adminPermissions") != null
                ? String.valueOf(request.getAttribute("adminPermissions"))
                : null;

        if (adminUserService.hasPermission(role, permissions, requiredPermission)) {
            return true;
        }

        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setContentType("application/json;charset=UTF-8");
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("message", "无权访问当前后台模块");
        payload.put("requiredPermission", requiredPermission);
        response.getWriter().write(JSON.toJSONString(payload));
        return false;
    }

    private String resolveRequiredPermission(String uri) {
        if (uri == null || !uri.startsWith("/admin/")) {
            return null;
        }
        if (uri.startsWith("/admin/auth/")) {
            return null;
        }
        if (uri.startsWith("/admin/dashboard/")) {
            return "dashboard:view";
        }
        if (uri.startsWith("/admin/statistics/")) {
            return "statistics:view";
        }
        if (uri.startsWith("/admin/operation-log/")) {
            return "operation-log:view";
        }
        if (uri.startsWith("/admin/admin/")) {
            return "admin:manage";
        }
        if (uri.startsWith("/admin/user") || uri.startsWith("/admin/users")) {
            return "user:manage";
        }
        if (uri.startsWith("/admin/group/")) {
            return "group:manage";
        }
        if (uri.startsWith("/admin/order/")) {
            return "order:manage";
        }
        if (uri.startsWith("/admin/report/")) {
            return "report:manage";
        }
        if (uri.startsWith("/admin/content-audit/")) {
            return "content-audit:manage";
        }
        if (uri.startsWith("/admin/system-config/")) {
            return "system-config:manage";
        }
        if (uri.startsWith("/admin/vip/")) {
            return "vip:manage";
        }
        if (uri.startsWith("/admin/pretty-number/")) {
            return "pretty-number:manage";
        }
        if (uri.startsWith("/admin/messages")) {
            return "message:monitor";
        }
        return null;
    }

    private Integer parseInteger(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return Integer.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return null;
        }
    }
}
