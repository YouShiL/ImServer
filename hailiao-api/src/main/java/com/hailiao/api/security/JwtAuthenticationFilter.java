package com.hailiao.api.security;

import com.hailiao.common.service.UserSessionService;
import com.hailiao.common.util.AppJwtUtil;
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

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    @Autowired
    private AppJwtUtil jwtUtil;

    @Autowired(required = false)
    private UserSessionService userSessionService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String requestURI = request.getRequestURI();

        if (requestURI.startsWith("/api/auth/") || requestURI.startsWith("/api/public/")
                || requestURI.startsWith("/swagger-ui") || requestURI.startsWith("/v3/api-docs")
                || requestURI.startsWith("/webjars") || requestURI.startsWith("/favicon.ico")) {
            filterChain.doFilter(request, response);
            return;
        }

        String header = request.getHeader("Authorization");

        if (header == null || !header.startsWith("Bearer ")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write("{\"code\": 401, \"message\": \"\\u7f3a\\u5c11\\u767b\\u5f55\\u51ed\\u8bc1\"}");
            return;
        }

        String token = header.substring(7);

        try {
            if (!jwtUtil.validateToken(token)) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json");
                response.getWriter().write("{\"code\": 401, \"message\": \"\\u767b\\u5f55\\u51ed\\u8bc1\\u65e0\\u6548\\u6216\\u5df2\\u8fc7\\u671f\"}");
                return;
            }

            Claims claims = jwtUtil.parseToken(token);
            Integer type = claims.get("type") != null ? Integer.valueOf(claims.get("type").toString()) : null;
            if (type == null || type != 1) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.setContentType("application/json");
                response.getWriter().write("{\"code\": 403, \"message\": \"\\u51ed\\u8bc1\\u7c7b\\u578b\\u9519\\u8bef\\uff0c\\u8bf7\\u4f7f\\u7528 App \\u7aef\\u767b\\u5f55\\u51ed\\u8bc1\"}");
                return;
            }

            Long userId = Long.valueOf(claims.get("userId").toString());
            String username = claims.get("username").toString();
            String sessionId = claims.get("sessionId") != null ? claims.get("sessionId").toString() : null;

            if (userSessionService != null && sessionId != null
                    && !userSessionService.isSessionActive(userId, sessionId)) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json");
                response.getWriter().write("{\"code\": 401, \"message\": \"\\u767b\\u5f55\\u4f1a\\u8bdd\\u5df2\\u5931\\u6548\\u6216\\u5df2\\u88ab\\u4e0b\\u7ebf\"}");
                return;
            }

            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(userId, null, new ArrayList<>());
            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

            SecurityContextHolder.getContext().setAuthentication(authentication);
            request.setAttribute("userId", userId);
            request.setAttribute("username", username);
            request.setAttribute("sessionId", sessionId);

            if (userSessionService != null && sessionId != null) {
                userSessionService.touchSession(sessionId);
            }

            filterChain.doFilter(request, response);
        } catch (Exception e) {
            logger.error("\\u004a\\u0057\\u0054 \\u9274\\u6743\\u5931\\u8d25: {}", e.getMessage());
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write("{\"code\": 401, \"message\": \"\\u767b\\u5f55\\u51ed\\u8bc1\\u6821\\u9a8c\\u5931\\u8d25\"}");
        }
    }
}
