package com.hailiao.api.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.info.License;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.annotations.security.SecuritySchemes;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(
        info = @Info(
                title = "嗨聊API接口文档",
                version = "1.0.0",
                description = "嗨聊即时通讯系统API接口文档，包含用户认证、消息、好友、群组等功能。\n\n"
                        + "## 认证说明\n"
                        + "除公开接口外，所有API调用需要在请求头中添加JWT令牌：\n"
                        + "```\n"
                        + "Authorization: Bearer {token}\n"
                        + "```\n\n"
                        + "## 响应格式\n"
                        + "所有接口统一返回以下格式：\n"
                        + "```json\n"
                        + "{\n"
                        + "  \"code\": 200,\n"
                        + "  \"message\": \"操作成功\",\n"
                        + "  \"data\": {}\n"
                        + "}\n"
                        + "```\n\n"
                        + "## 错误码说明\n"
                        + "- 200: 成功\n"
                        + "- 400: 参数错误\n"
                        + "- 401: 未授权（令牌无效或过期）\n"
                        + "- 403: 禁止访问\n"
                        + "- 404: 资源不存在\n"
                        + "- 500: 服务器内部错误"
        ),
        security = @SecurityRequirement(name = "Bearer")
)
@SecuritySchemes({
        @SecurityScheme(
                name = "Bearer",
                type = io.swagger.v3.oas.annotations.enums.SecuritySchemeType.HTTP,
                scheme = "bearer",
                bearerFormat = "JWT"
        )
})
public class OpenApiConfig {
}
