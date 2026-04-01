package com.hailiao.admin.controller;

import com.hailiao.common.entity.PrettyNumber;
import com.hailiao.common.service.PrettyNumberService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 靓号管理控制器。
 */
@RestController
@RequestMapping("/admin/pretty-number")
public class PrettyNumberManageController {

    @Autowired
    private PrettyNumberService prettyNumberService;

    /**
     * 分页获取靓号列表。
     */
    @GetMapping("/list")
    public ResponseEntity<?> getPrettyNumberList(
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Integer level,
            @RequestParam(required = false) Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<PrettyNumber> prettyNumbers = prettyNumberService.getPrettyNumberList(status, level, userId, pageable);
            return ResponseEntity.ok(toPrettyNumberPageResponse(prettyNumbers));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 根据 ID 获取靓号详情。
     */
    @GetMapping("/{prettyNumberId}")
    public ResponseEntity<?> getPrettyNumberById(@PathVariable Long prettyNumberId) {
        try {
            PrettyNumber prettyNumber = prettyNumberService.getPrettyNumberById(prettyNumberId);
            return ResponseEntity.ok(toPrettyNumberResponse(prettyNumber));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 创建靓号。
     */
    @PostMapping
    public ResponseEntity<?> createPrettyNumber(@RequestBody Map<String, Object> request) {
        try {
            String number = (String) request.get("number");
            Integer level = Integer.valueOf(request.get("level").toString());
            BigDecimal price = new BigDecimal(request.get("price").toString());
            PrettyNumber prettyNumber = prettyNumberService.createPrettyNumber(number, level, price);
            return ResponseEntity.ok(toPrettyNumberResponse(prettyNumber));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 更新靓号价格。
     */
    @PutMapping("/{prettyNumberId}/price")
    public ResponseEntity<?> updatePrice(
            @PathVariable Long prettyNumberId,
            @RequestBody Map<String, Object> request) {
        try {
            BigDecimal price = new BigDecimal(request.get("price").toString());
            PrettyNumber prettyNumber = prettyNumberService.updatePrettyNumberPrice(prettyNumberId, price);
            return ResponseEntity.ok(toPrettyNumberResponse(prettyNumber));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 释放靓号。
     */
    @PostMapping("/{prettyNumberId}/release")
    public ResponseEntity<?> releasePrettyNumber(@PathVariable Long prettyNumberId) {
        try {
            prettyNumberService.releasePrettyNumber(prettyNumberId);
            return ResponseEntity.ok("\u91ca\u653e\u6210\u529f");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * 获取靓号统计信息。
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getPrettyNumberStats() {
        try {
            long totalPrettyNumbers = prettyNumberService.getTotalPrettyNumberCount();
            long availablePrettyNumbers = prettyNumberService.getAvailablePrettyNumberCount();
            long soldPrettyNumbers = prettyNumberService.getSoldPrettyNumberCount();
            Map<String, Object> stats = new LinkedHashMap<String, Object>();
            stats.put("totalPrettyNumbers", totalPrettyNumbers);
            stats.put("availablePrettyNumbers", availablePrettyNumbers);
            stats.put("soldPrettyNumbers", soldPrettyNumbers);
            stats.put("summary", mapOf(
                    "availableLabel", "\u5f85\u552e\u9753\u53f7",
                    "soldLabel", "\u5df2\u552e\u9753\u53f7",
                    "soldRatio", totalPrettyNumbers == 0 ? "0.00%" : String.format("%.2f%%", (soldPrettyNumbers * 100.0) / totalPrettyNumbers)
            ));
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    private Map<String, Object> toPrettyNumberPageResponse(Page<PrettyNumber> prettyNumbers) {
        List<Map<String, Object>> content = new ArrayList<Map<String, Object>>();
        long soldCount = 0L;
        long availableCount = 0L;
        for (PrettyNumber prettyNumber : prettyNumbers.getContent()) {
            content.add(toPrettyNumberResponse(prettyNumber));
            if (prettyNumber.getStatus() != null && prettyNumber.getStatus() == 1) {
                soldCount++;
            } else {
                availableCount++;
            }
        }

        Map<String, Object> summary = new LinkedHashMap<String, Object>();
        summary.put("filteredTotal", prettyNumbers.getTotalElements());
        summary.put("currentPageCount", prettyNumbers.getNumberOfElements());
        summary.put("soldCount", soldCount);
        summary.put("availableCount", availableCount);

        Map<String, Object> page = new LinkedHashMap<String, Object>();
        page.put("content", content);
        page.put("page", prettyNumbers.getNumber());
        page.put("size", prettyNumbers.getSize());
        page.put("totalElements", prettyNumbers.getTotalElements());
        page.put("totalPages", prettyNumbers.getTotalPages());
        page.put("first", prettyNumbers.isFirst());
        page.put("last", prettyNumbers.isLast());
        page.put("summary", summary);
        return page;
    }

    private Map<String, Object> toPrettyNumberResponse(PrettyNumber prettyNumber) {
        Map<String, Object> item = new LinkedHashMap<String, Object>();
        item.put("id", prettyNumber.getId());
        item.put("number", prettyNumber.getNumber());
        item.put("level", prettyNumber.getLevel());
        item.put("levelLabel", getPrettyNumberLevelLabel(prettyNumber.getLevel()));
        item.put("price", prettyNumber.getPrice());
        item.put("status", prettyNumber.getStatus());
        item.put("statusLabel", prettyNumber.getStatus() != null && prettyNumber.getStatus() == 1 ? "\u5df2\u552e\u51fa" : "\u5f85\u552e");
        item.put("userId", prettyNumber.getUserId());
        item.put("buyTime", prettyNumber.getBuyTime());
        item.put("expireTime", prettyNumber.getExpireTime());
        item.put("createdAt", prettyNumber.getCreatedAt());
        return item;
    }

    private String getPrettyNumberLevelLabel(Integer level) {
        if (level == null) {
            return "\u672a\u77e5\u7b49\u7ea7";
        }
        if (level == 1) {
            return "\u666e\u901a\u9753\u53f7";
        }
        if (level == 2) {
            return "\u7cbe\u9009\u9753\u53f7";
        }
        if (level == 3) {
            return "\u7a00\u7f3a\u9753\u53f7";
        }
        return "\u7b49\u7ea7" + level;
    }

    private Map<String, Object> mapOf(Object... values) {
        LinkedHashMap<String, Object> map = new LinkedHashMap<String, Object>();
        for (int i = 0; i < values.length; i += 2) {
            map.put(String.valueOf(values[i]), values[i + 1]);
        }
        return map;
    }
}
