package com.hailiao.admin.controller;

import com.hailiao.common.entity.PrettyNumber;
import com.hailiao.common.service.PrettyNumberService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PrettyNumberManageControllerTest {

    @Mock
    private PrettyNumberService prettyNumberService;

    @InjectMocks
    private PrettyNumberManageController prettyNumberManageController;

    @Test
    void getPrettyNumberListReturnsSummaryAndLabels() {
        PrettyNumber prettyNumber = new PrettyNumber();
        prettyNumber.setId(1L);
        prettyNumber.setNumber("88888");
        prettyNumber.setLevel(3);
        prettyNumber.setStatus(1);

        List<PrettyNumber> prettyNumbers = new ArrayList<PrettyNumber>();
        prettyNumbers.add(prettyNumber);
        Page<PrettyNumber> page = new PageImpl<PrettyNumber>(prettyNumbers, PageRequest.of(0, 20), 1);
        when(prettyNumberService.getPrettyNumberList(1, 3, null, PageRequest.of(0, 20, org.springframework.data.domain.Sort.by("createdAt").descending())))
                .thenReturn(page);

        ResponseEntity<?> actual = prettyNumberManageController.getPrettyNumberList(1, 3, null, 0, 20);

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals(1L, summary.get("filteredTotal"));
        assertEquals(1L, summary.get("soldCount"));

        List<?> content = assertInstanceOf(List.class, body.get("content"));
        Map<?, ?> first = assertInstanceOf(Map.class, content.get(0));
        assertEquals("稀缺靓号", first.get("levelLabel"));
        assertEquals("已售出", first.get("statusLabel"));
    }

    @Test
    void getPrettyNumberStatsReturnsSummaryBlock() {
        when(prettyNumberService.getTotalPrettyNumberCount()).thenReturn(20L);
        when(prettyNumberService.getAvailablePrettyNumberCount()).thenReturn(8L);
        when(prettyNumberService.getSoldPrettyNumberCount()).thenReturn(12L);

        ResponseEntity<?> actual = prettyNumberManageController.getPrettyNumberStats();

        assertEquals(HttpStatus.OK, actual.getStatusCode());
        Map<?, ?> body = assertInstanceOf(Map.class, actual.getBody());
        assertEquals(20L, body.get("totalPrettyNumbers"));
        assertEquals(8L, body.get("availablePrettyNumbers"));
        assertEquals(12L, body.get("soldPrettyNumbers"));
        Map<?, ?> summary = assertInstanceOf(Map.class, body.get("summary"));
        assertEquals("已售靓号", summary.get("soldLabel"));
        verify(prettyNumberService).getSoldPrettyNumberCount();
    }
}
