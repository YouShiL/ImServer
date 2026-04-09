package com.hailiao.api.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * 注册 {@link ImProperties}，并在启动时打印一条 [im.migrate] 观测日志（不改变业务行为）。
 */
@Configuration
@EnableConfigurationProperties(ImProperties.class)
public class ImModuleConfiguration implements InitializingBean {

    private static final Logger log = LoggerFactory.getLogger(ImModuleConfiguration.class);

    private final ImProperties imProperties;

    public ImModuleConfiguration(ImProperties imProperties) {
        this.imProperties = imProperties;
    }

    @Override
    public void afterPropertiesSet() {
        log.info(
                "[im.migrate] im module loaded: migration.mode={}, wukong.enabled={}, webhook.enabled={}, "
                        + "send.via-server={}, client.direct-send-fallback={}",
                imProperties.getMigration().getMode(),
                imProperties.getWukong().isEnabled(),
                imProperties.getWebhook().isEnabled(),
                imProperties.getSend().isViaServer(),
                imProperties.getClient().isDirectSendFallback());
    }
}
