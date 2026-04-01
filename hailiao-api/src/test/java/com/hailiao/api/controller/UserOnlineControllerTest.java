package com.hailiao.api.controller;

import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.service.UserOnlineService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserOnlineControllerTest {

    @Mock
    private UserOnlineService userOnlineService;

    @InjectMocks
    private UserOnlineController userOnlineController;

    @Test
    void getOnlineStatusShouldReturnUserOnlineInfo() {
        Map<String, Object> info = new HashMap<String, Object>();
        info.put("exists", true);
        info.put("isOnline", true);

        when(userOnlineService.getUserOnlineInfo(1L, 2L)).thenReturn(info);

        ResponseEntity<ResponseDTO> response = userOnlineController.getOnlineStatus(1L, 2L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(info, response.getBody().getData());
    }

    @Test
    void batchGetOnlineStatusShouldReturnStatusMap() {
        List<Long> userIds = new ArrayList<Long>();
        userIds.add(1L);
        userIds.add(2L);
        Map<Long, Boolean> status = new HashMap<Long, Boolean>();
        status.put(1L, true);
        status.put(2L, false);

        when(userOnlineService.batchGetOnlineStatus(userIds)).thenReturn(status);

        ResponseEntity<ResponseDTO> response = userOnlineController.batchGetOnlineStatus(userIds);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(status, response.getBody().getData());
    }

    @Test
    void updateOnlineSettingsShouldDelegateToService() {
        ResponseEntity<ResponseDTO> response = userOnlineController.updateOnlineSettings(1L, true, false);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(userOnlineService).updateOnlineStatusSetting(1L, true, false);
    }

    @Test
    void setOnlineAndOfflineShouldDelegateToService() {
        ResponseEntity<ResponseDTO> online = userOnlineController.setOnline(1L);
        ResponseEntity<ResponseDTO> offline = userOnlineController.setOffline(1L);

        assertEquals(HttpStatus.OK, online.getStatusCode());
        assertEquals(HttpStatus.OK, offline.getStatusCode());
        verify(userOnlineService).setUserOnline(1L);
        verify(userOnlineService).setUserOffline(1L);
    }
}
