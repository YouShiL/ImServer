package com.hailiao.common.service;

import com.hailiao.common.entity.SystemConfig;
import com.hailiao.common.repository.SystemConfigRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;

@Service
public class SystemConfigService {

    @Autowired
    private SystemConfigRepository systemConfigRepository;

    @Transactional
    public SystemConfig createConfig(SystemConfig config) {
        if (systemConfigRepository.existsByConfigKey(config.getConfigKey())) {
            throw new RuntimeException("配置键已存在");
        }
        config.setUpdatedAt(new Date());
        return systemConfigRepository.save(config);
    }

    public SystemConfig getConfigById(Long id) {
        return systemConfigRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("配置不存在"));
    }

    public SystemConfig getConfigByKey(String configKey) {
        return systemConfigRepository.findByConfigKey(configKey)
                .orElseThrow(() -> new RuntimeException("配置不存在"));
    }

    public String getConfigValue(String configKey, String defaultValue) {
        return systemConfigRepository.findByConfigKey(configKey)
                .map(SystemConfig::getConfigValue)
                .orElse(defaultValue);
    }

    public List<SystemConfig> getAllConfigs() {
        return systemConfigRepository.findAll();
    }

    public List<SystemConfig> getConfigsByCategory(String category) {
        return systemConfigRepository.findByCategory(category);
    }

    @Transactional
    public SystemConfig updateConfig(Long id, String configValue, String description, Long updatedBy) {
        SystemConfig config = getConfigById(id);
        if (configValue != null) {
            config.setConfigValue(configValue);
        }
        if (description != null) {
            config.setDescription(description);
        }
        config.setUpdatedBy(updatedBy);
        config.setUpdatedAt(new Date());
        return systemConfigRepository.save(config);
    }

    @Transactional
    public void deleteConfig(Long id) {
        systemConfigRepository.deleteById(id);
    }
}
