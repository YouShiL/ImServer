package com.hailiao.admin.controller;

import com.hailiao.common.entity.SystemConfig;
import com.hailiao.common.service.SystemConfigService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin/system-config")
public class SystemConfigManageController {

    @Autowired
    private SystemConfigService systemConfigService;

    @GetMapping("/list")
    public ResponseEntity<?> getConfigList() {
        try {
            return ResponseEntity.ok(toConfigListResponse(systemConfigService.getAllConfigs()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/category/{category}")
    public ResponseEntity<?> getConfigsByCategory(@PathVariable String category) {
        try {
            return ResponseEntity.ok(toConfigListResponse(systemConfigService.getConfigsByCategory(category)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/{configId}")
    public ResponseEntity<?> getConfigById(@PathVariable Long configId) {
        try {
            return ResponseEntity.ok(toConfigResponse(systemConfigService.getConfigById(configId)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/key/{configKey}")
    public ResponseEntity<?> getConfigByKey(@PathVariable String configKey) {
        try {
            return ResponseEntity.ok(toConfigResponse(systemConfigService.getConfigByKey(configKey)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping
    public ResponseEntity<?> createConfig(@RequestBody SystemConfig config) {
        try {
            return ResponseEntity.ok(toConfigResponse(systemConfigService.createConfig(config)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PutMapping("/{configId}")
    public ResponseEntity<?> updateConfig(
            @RequestAttribute("adminId") Long adminId,
            @PathVariable Long configId,
            @RequestBody SystemConfig config) {
        try {
            return ResponseEntity.ok(toConfigResponse(systemConfigService.updateConfig(
                    configId,
                    config.getConfigValue(),
                    config.getDescription(),
                    adminId
            )));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @DeleteMapping("/{configId}")
    public ResponseEntity<?> deleteConfig(@PathVariable Long configId) {
        try {
            systemConfigService.deleteConfig(configId);
            return ResponseEntity.ok("\u5220\u9664\u6210\u529f");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    private Map<String, Object> toConfigListResponse(List<SystemConfig> configs) {
        List<Map<String, Object>> content = new ArrayList<Map<String, Object>>();
        LinkedHashSet<String> categories = new LinkedHashSet<String>();
        for (SystemConfig config : configs) {
            content.add(toConfigResponse(config));
            if (config.getCategory() != null && !config.getCategory().trim().isEmpty()) {
                categories.add(config.getCategory());
            }
        }

        Map<String, Object> response = new LinkedHashMap<String, Object>();
        response.put("content", content);
        response.put("summary", mapOf(
                "filteredTotal", configs.size(),
                "categoryCount", categories.size(),
                "categories", new ArrayList<String>(categories)
        ));
        return response;
    }

    private Map<String, Object> toConfigResponse(SystemConfig config) {
        Map<String, Object> item = new LinkedHashMap<String, Object>();
        item.put("id", config.getId());
        item.put("configKey", config.getConfigKey());
        item.put("configValue", config.getConfigValue());
        item.put("description", config.getDescription());
        item.put("category", config.getCategory());
        item.put("categoryLabel", config.getCategory() == null || config.getCategory().trim().isEmpty() ? "\u672a\u5206\u7c7b" : config.getCategory());
        item.put("updatedBy", config.getUpdatedBy());
        item.put("updatedAt", config.getUpdatedAt());
        return item;
    }

    private Map<String, Object> mapOf(Object... values) {
        LinkedHashMap<String, Object> map = new LinkedHashMap<String, Object>();
        for (int i = 0; i < values.length; i += 2) {
            map.put(String.valueOf(values[i]), values[i + 1]);
        }
        return map;
    }
}
