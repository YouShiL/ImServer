package com.hailiao.admin.interceptor;

import com.hailiao.common.entity.OperationLog;
import com.hailiao.common.service.OperationLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@Component
public class AdminOperationLogInterceptor implements HandlerInterceptor {

    private static final String ATTR_START_TIME = "adminOperationLogStartTime";

    @Autowired
    private OperationLogService operationLogService;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        request.setAttribute(ATTR_START_TIME, System.currentTimeMillis());
        return true;
    }

    @Override
    public void afterCompletion(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler,
            Exception ex) {
        if (!shouldLog(request)) {
            return;
        }

        try {
            OperationLog log = new OperationLog();
            Long adminId = parseLong(request.getAttribute("adminId"));
            String username = request.getAttribute("username") != null
                    ? String.valueOf(request.getAttribute("username"))
                    : null;

            log.setUserId(adminId);
            log.setUsername(username);
            log.setOperationType(resolveOperationType(request.getMethod(), request.getRequestURI()));
            log.setModule(resolveModule(request.getRequestURI()));
            log.setDescription(resolveDescription(request));
            log.setRequestMethod(request.getMethod());
            log.setRequestUrl(request.getRequestURI());
            log.setRequestParams(buildRequestParams(request));
            log.setResponseData("status=" + response.getStatus());
            log.setIp(resolveClientIp(request));
            log.setStatus(ex == null && response.getStatus() < 400 ? 1 : 0);
            log.setErrorMsg(ex != null ? ex.getMessage() : null);
            log.setExecuteTime(resolveExecuteTime(request));
            operationLogService.saveLog(log);
        } catch (Exception ignored) {
            // Logging must never block the admin request path.
        }
    }

    private boolean shouldLog(HttpServletRequest request) {
        String method = request.getMethod();
        if (!("POST".equalsIgnoreCase(method) || "PUT".equalsIgnoreCase(method) || "DELETE".equalsIgnoreCase(method))) {
            return false;
        }
        String uri = request.getRequestURI();
        return uri != null && uri.startsWith("/admin/") && !uri.startsWith("/admin/auth/");
    }

    private String resolveOperationType(String method, String uri) {
        if (uri != null) {
            if (uri.matches("^/admin/admin/\\d+/permissions$")) {
                return "ADMIN_PERMISSION_UPDATE";
            }
            if (uri.matches("^/admin/admin/\\d+/reset-password$")) {
                return "ADMIN_PASSWORD_RESET";
            }
            if ("/admin/admin".equals(uri) && "POST".equalsIgnoreCase(method)) {
                return "ADMIN_CREATE";
            }
            if (uri.matches("^/admin/admin/\\d+$") && "PUT".equalsIgnoreCase(method)) {
                return "ADMIN_UPDATE";
            }
            if (uri.matches("^/admin/admin/\\d+$") && "DELETE".equalsIgnoreCase(method)) {
                return "ADMIN_DELETE";
            }
        }
        if ("POST".equalsIgnoreCase(method)) {
            return "CREATE_OR_ACTION";
        }
        if ("PUT".equalsIgnoreCase(method)) {
            return "UPDATE";
        }
        if ("DELETE".equalsIgnoreCase(method)) {
            return "DELETE";
        }
        return method;
    }

    private String resolveModule(String uri) {
        if (uri == null) {
            return "unknown";
        }
        if (uri.startsWith("/admin/admin")) {
            return "admin-user";
        }
        if (uri.startsWith("/admin/operation-log")) {
            return "operation-log";
        }
        if (uri.startsWith("/admin/user")) {
            return "user";
        }
        if (uri.startsWith("/admin/group")) {
            return "group";
        }
        if (uri.startsWith("/admin/order")) {
            return "order";
        }
        if (uri.startsWith("/admin/report")) {
            return "report";
        }
        if (uri.startsWith("/admin/content-audit")) {
            return "content-audit";
        }
        if (uri.startsWith("/admin/system-config")) {
            return "system-config";
        }
        if (uri.startsWith("/admin/vip")) {
            return "vip";
        }
        if (uri.startsWith("/admin/pretty-number")) {
            return "pretty-number";
        }
        if (uri.startsWith("/admin/messages")) {
            return "message-monitor";
        }
        if (uri.startsWith("/admin/dashboard")) {
            return "dashboard";
        }
        if (uri.startsWith("/admin/statistics")) {
            return "statistics";
        }
        String[] parts = uri.split("/");
        return parts.length >= 3 ? parts[2] : "unknown";
    }

    private String resolveDescription(HttpServletRequest request) {
        String uri = request.getRequestURI();
        String method = request.getMethod();
        String targetSummary = resolveTargetSummary(request);
        if (uri.matches("^/admin/admin/\\d+/permissions$")) {
            return appendTargetSummary("\u66f4\u65b0\u7ba1\u7406\u5458\u89d2\u8272\u548c\u6743\u9650", targetSummary);
        }
        if (uri.matches("^/admin/admin/\\d+/reset-password$")) {
            return appendTargetSummary("\u91cd\u7f6e\u7ba1\u7406\u5458\u5bc6\u7801", targetSummary);
        }
        if ("/admin/admin".equals(uri) && "POST".equalsIgnoreCase(method)) {
            return appendTargetSummary("\u521b\u5efa\u7ba1\u7406\u5458", targetSummary);
        }
        if (uri.matches("^/admin/admin/\\d+$") && "PUT".equalsIgnoreCase(method)) {
            return appendTargetSummary("\u66f4\u65b0\u7ba1\u7406\u5458\u4fe1\u606f", targetSummary);
        }
        if (uri.matches("^/admin/admin/\\d+$") && "DELETE".equalsIgnoreCase(method)) {
            return appendTargetSummary("\u5220\u9664\u7ba1\u7406\u5458", targetSummary);
        }
        return method + " " + uri;
    }

    private String resolveTargetSummary(HttpServletRequest request) {
        Object targetAdminId = request.getAttribute("targetAdminId");
        Object targetUsername = request.getAttribute("targetAdminUsername");
        Object targetRoleName = request.getAttribute("targetAdminRoleName");
        Object permissionSummary = request.getAttribute("targetPermissionSummary");

        StringBuilder builder = new StringBuilder();
        if (targetAdminId != null) {
            builder.append("ID=").append(targetAdminId);
        }
        if (targetUsername != null) {
            if (builder.length() > 0) {
                builder.append(", ");
            }
            builder.append("\u7528\u6237\u540d=").append(targetUsername);
        }
        if (targetRoleName != null) {
            if (builder.length() > 0) {
                builder.append(", ");
            }
            builder.append("\u89d2\u8272=").append(targetRoleName);
        }
        if (permissionSummary != null) {
            if (builder.length() > 0) {
                builder.append(", ");
            }
            builder.append("\u6743\u9650=").append(permissionSummary);
        }
        return builder.toString();
    }

    private String appendTargetSummary(String base, String targetSummary) {
        if (targetSummary == null || targetSummary.trim().isEmpty()) {
            return base;
        }
        return base + " [" + targetSummary + "]";
    }

    private String buildRequestParams(HttpServletRequest request) {
        String queryString = request.getQueryString();
        return queryString == null ? "" : queryString;
    }

    private String resolveClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.trim().isEmpty()) {
            return forwarded.split(",")[0].trim();
        }
        String realIp = request.getHeader("X-Real-IP");
        if (realIp != null && !realIp.trim().isEmpty()) {
            return realIp.trim();
        }
        return request.getRemoteAddr();
    }

    private Long resolveExecuteTime(HttpServletRequest request) {
        Object startTime = request.getAttribute(ATTR_START_TIME);
        if (!(startTime instanceof Long)) {
            return null;
        }
        return System.currentTimeMillis() - (Long) startTime;
    }

    private Long parseLong(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return Long.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return null;
        }
    }
}
