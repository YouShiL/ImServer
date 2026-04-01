package com.hailiao.admin.controller;

import com.hailiao.common.entity.SystemConfig;
import com.hailiao.common.service.SystemConfigService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SystemConfigManageControllerTest {

    @Mock
    private SystemConfigService systemConfigService;

    @InjectMocks
    private SystemConfigManageController systemConfigManageController;

    @Test
    void getConfigListReturnsSummaryAndLabels() {
        SystemConfig config = new SystemConfig();
        config.setId(1L);
        config.setConfigKey("im.maxGroupCount");
        config.setConfigValue("500");
        config.setCategory("group");

        List<SystemConfig> configs = new ArrayList<SystemConfig>();
        configs.add(config);
        when(systemConfigService.getAllConfigs()).thenReturn(configs);

        ResponseEntity<?> actual = systemConfigManageController.getConfigList();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals(1, summary.get("filteredTotal"));
        assertEquals(1, summary.get("categoryCount"));

        List<?> content = assertInstanceOf(List.class, body.get("content"));
        Map<?, ?> first = assertInstanceOf(Map.class, content.get(0));
        assertEquals("group", first.get("categoryLabel"));
    }
}
