package com.hailiao.common.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.SignatureException;
import io.jsonwebtoken.UnsupportedJwtException;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Component
public class JwtUtil {

    private static final String SECRET = "hailiao-im-secret-key-for-jwt-token-generation-2024";
    private static final long EXPIRATION = 86400000;
    private static final SecretKey KEY = Keys.hmacShaKeyFor(SECRET.getBytes(StandardCharsets.UTF_8));

    public String generateToken(Long userId, String username, Integer type) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", userId);
        claims.put("username", username);
        claims.put("type", type);

        return Jwts.builder()
                .setClaims(claims)
                .setSubject(String.valueOf(userId))
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + EXPIRATION))
                .signWith(KEY, SignatureAlgorithm.HS256)
                .compact();
    }

    public Claims parseToken(String token) {
        try {
            return Jwts.parserBuilder()
                    .setSigningKey(KEY)
                    .build()
                    .parseClaimsJws(token)
                    .getBody();
        } catch (ExpiredJwtException e) {
            throw new RuntimeException("\u767b\u5f55\u51ed\u8bc1\u5df2\u8fc7\u671f");
        } catch (UnsupportedJwtException e) {
            throw new RuntimeException("\u4e0d\u652f\u6301\u7684\u767b\u5f55\u51ed\u8bc1");
        } catch (MalformedJwtException e) {
            throw new RuntimeException("\u767b\u5f55\u51ed\u8bc1\u683c\u5f0f\u9519\u8bef");
        } catch (SignatureException e) {
            throw new RuntimeException("\u767b\u5f55\u51ed\u8bc1\u7b7e\u540d\u9519\u8bef");
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("\u767b\u5f55\u51ed\u8bc1\u4e3a\u7a7a\u6216\u975e\u6cd5");
        }
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder().setSigningKey(KEY).build().parseClaimsJws(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public Long getUserIdFromToken(String token) {
        Claims claims = parseToken(token);
        return Long.valueOf(claims.get("userId").toString());
    }

    public String getUsernameFromToken(String token) {
        Claims claims = parseToken(token);
        return claims.get("username").toString();
    }

    public Integer getTypeFromToken(String token) {
        Claims claims = parseToken(token);
        return Integer.valueOf(claims.get("type").toString());
    }
}
