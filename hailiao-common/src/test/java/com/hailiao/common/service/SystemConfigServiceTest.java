package com.hailiao.common.service;

import com.hailiao.common.entity.SystemConfig;
import com.hailiao.common.repository.SystemConfigRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SystemConfigServiceTest {

    @Mock
    private SystemConfigRepository systemConfigRepository;

    @InjectMocks
    private SystemConfigService systemConfigService;

    @Test
    void createConfigShouldRejectDuplicateKey() {
        SystemConfig config = new SystemConfig();
        config.setConfigKey("site.name");

        when(systemConfigRepository.existsByConfigKey("site.name")).thenReturn(true);

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        systemConfigService.createConfig(config);
                    }
                });

        assertEquals("\u914d\u7f6e\u952e\u5df2\u5b58\u5728", error.getMessage());
    }

    @Test
    void createConfigShouldSetUpdatedAt() {
        SystemConfig config = new SystemConfig();
        config.setConfigKey("site.name");

        when(systemConfigRepository.existsByConfigKey("site.name")).thenReturn(false);
        when(systemConfigRepository.save(any(SystemConfig.class))).thenAnswer(new org.mockito.stubbing.Answer<SystemConfig>() {
            @Override
            public SystemConfig answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (SystemConfig) invocation.getArgument(0);
            }
        });

        SystemConfig saved = systemConfigService.createConfig(config);

        assertNotNull(saved.getUpdatedAt());
    }

    @Test
    void getConfigValueShouldReturnDefaultWhenMissing() {
        when(systemConfigRepository.findByConfigKey("unknown.key")).thenReturn(Optional.<SystemConfig>empty());

        String value = systemConfigService.getConfigValue("unknown.key", "default-value");

        assertEquals("default-value", value);
    }

    @Test
    void updateConfigShouldReplaceMutableFields() {
        SystemConfig config = new SystemConfig();
        config.setId(1L);
        config.setConfigKey("site.name");
        config.setConfigValue("old");
        config.setDescription("desc");

        when(systemConfigRepository.findById(1L)).thenReturn(Optional.of(config));
        when(systemConfigRepository.save(any(SystemConfig.class))).thenAnswer(new org.mockito.stubbing.Answer<SystemConfig>() {
            @Override
            public SystemConfig answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (SystemConfig) invocation.getArgument(0);
            }
        });

        SystemConfig saved = systemConfigService.updateConfig(1L, "new-value", "new-desc", 9L);

        assertEquals("new-value", saved.getConfigValue());
        assertEquals("new-desc", saved.getDescription());
        assertEquals(Long.valueOf(9L), saved.getUpdatedBy());
        assertNotNull(saved.getUpdatedAt());
    }

    @Test
    void deleteConfigShouldDelegateToRepository() {
        systemConfigService.deleteConfig(5L);

        verify(systemConfigRepository).deleteById(5L);
    }
}
