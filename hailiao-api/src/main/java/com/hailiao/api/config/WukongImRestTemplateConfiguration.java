package com.hailiao.api.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;

/**
 * 仅为 {@code im.wukong.enabled=true} 时提供 RestTemplate，避免默认引入无用 Bean。
 */
@Configuration
@ConditionalOnProperty(name = "im.wukong.enabled", havingValue = "true")
public class WukongImRestTemplateConfiguration {

    @Bean
    public RestTemplate wukongImRestTemplate(RestTemplateBuilder builder) {
        return builder
                .setConnectTimeout(Duration.ofSeconds(5))
                .setReadTimeout(Duration.ofSeconds(15))
                .build();
    }
}
