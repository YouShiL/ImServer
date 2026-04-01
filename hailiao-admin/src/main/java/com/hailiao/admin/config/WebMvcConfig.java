package com.hailiao.admin.config;

import com.hailiao.admin.interceptor.AdminOperationLogInterceptor;
import com.hailiao.admin.interceptor.AdminPermissionInterceptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Autowired
    private AdminOperationLogInterceptor adminOperationLogInterceptor;

    @Autowired
    private AdminPermissionInterceptor adminPermissionInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(adminPermissionInterceptor)
                .addPathPatterns("/admin/**")
                .excludePathPatterns("/admin/auth/**");

        registry.addInterceptor(adminOperationLogInterceptor)
                .addPathPatterns("/admin/**")
                .excludePathPatterns("/admin/auth/**");
    }
}
