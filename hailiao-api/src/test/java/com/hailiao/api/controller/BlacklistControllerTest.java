package com.hailiao.api.controller;

import com.hailiao.api.dto.AddToBlacklistRequestDTO;
import com.hailiao.api.dto.BlacklistDTO;
import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.Blacklist;
import com.hailiao.common.entity.User;
import com.hailiao.common.service.BlacklistService;
import com.hailiao.common.service.UserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BlacklistControllerTest {

    @Mock
    private BlacklistService blacklistService;

    @Mock
    private UserService userService;

    @InjectMocks
    private BlacklistController blacklistController;

    @Test
    void addToBlacklistShouldReturnConvertedDto() {
        AddToBlacklistRequestDTO request = new AddToBlacklistRequestDTO();
        request.setBlockedUserId(2L);

        Blacklist blacklist = new Blacklist();
        blacklist.setId(1L);
        blacklist.setUserId(1L);
        blacklist.setBlockedUserId(2L);
        blacklist.setCreatedAt(new Date());

        User blockedUser = new User();
        blockedUser.setId(2L);
        blockedUser.setUserId("1000000002");
        blockedUser.setNickname("被拉黑用户");
        blockedUser.setAvatar("avatar.png");

        when(blacklistService.addToBlacklist(1L, 2L)).thenReturn(blacklist);
        when(userService.getUserById(2L)).thenReturn(blockedUser);

        ResponseEntity<ResponseDTO<BlacklistDTO>> response = blacklistController.addToBlacklist(1L, request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("被拉黑用户", response.getBody().getData().getBlockedUserInfo().getNickname());
    }

    @Test
    void getBlacklistShouldReturnConvertedDtos() {
        List<Blacklist> blacklists = new ArrayList<Blacklist>();
        Blacklist blacklist = new Blacklist();
        blacklist.setId(1L);
        blacklist.setUserId(1L);
        blacklist.setBlockedUserId(2L);
        blacklists.add(blacklist);

        User blockedUser = new User();
        blockedUser.setId(2L);
        blockedUser.setUserId("1000000002");
        blockedUser.setNickname("被拉黑用户");

        when(blacklistService.getBlacklist(1L)).thenReturn(blacklists);
        when(userService.getUserById(2L)).thenReturn(blockedUser);

        ResponseEntity<ResponseDTO<List<BlacklistDTO>>> response = blacklistController.getBlacklist(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().getData().size());
        assertEquals(Long.valueOf(2L), response.getBody().getData().get(0).getBlockedUserId());
    }

    @Test
    void removeFromBlacklistShouldDelegateToService() {
        ResponseEntity<ResponseDTO<String>> response = blacklistController.removeFromBlacklist(1L, 2L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(blacklistService).removeFromBlacklist(1L, 2L);
    }

    @Test
    void isBlockedShouldReturnServiceValue() {
        when(blacklistService.isBlocked(1L, 2L)).thenReturn(true);

        ResponseEntity<ResponseDTO<Boolean>> response = blacklistController.isBlocked(1L, 2L);

        assertEquals(Boolean.TRUE, response.getBody().getData());
    }
}
