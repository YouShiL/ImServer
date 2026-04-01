package com.hailiao.admin.security;

import com.hailiao.common.entity.AdminUser;
import com.hailiao.common.service.AdminUserService;
import com.hailiao.common.util.AdminJwtUtil;
import io.jsonwebtoken.Claims;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Set;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    @Autowired
    private AdminJwtUtil jwtUtil;

    @Autowired
    private AdminUserService adminUserService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = header.substring(7);
        try {
            Claims claims = jwtUtil.parseToken(token);
            Integer type = Integer.valueOf(claims.get("type").toString());
            if (type != 2) {
                filterChain.doFilter(request, response);
                return;
            }

            Long userId = Long.valueOf(claims.get("userId").toString());
            String username = claims.get("username").toString();
            AdminUser adminUser = adminUserService.getAdminUserById(userId);

            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(userId, null, new ArrayList<>());
            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

            SecurityContextHolder.getContext().setAuthentication(authentication);
            request.setAttribute("adminId", userId);
            request.setAttribute("username", username);
            request.setAttribute("adminRole", adminUser.getRole());
            request.setAttribute("adminPermissions", adminUser.getPermissions());
            Set<String> effectivePermissions = adminUserService.getEffectivePermissions(adminUser);
            request.setAttribute("effectivePermissions", effectivePermissions);
        } catch (Exception e) {
            logger.error("\u540e\u53f0 JWT \u6821\u9a8c\u5931\u8d25: {}", e.getMessage());
        }

        filterChain.doFilter(request, response);
    }
}
