package com.hailiao.common.service;

import com.hailiao.common.entity.Blacklist;
import com.hailiao.common.repository.BlacklistRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BlacklistServiceTest {

    @Mock
    private BlacklistRepository blacklistRepository;

    @InjectMocks
    private BlacklistService blacklistService;

    @Test
    void addToBlacklistShouldRejectSelfBlock() {
        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        blacklistService.addToBlacklist(1L, 1L);
                    }
                });

        assertEquals("不能拉黑自己", error.getMessage());
    }

    @Test
    void addToBlacklistShouldRejectDuplicateBlock() {
        when(blacklistRepository.existsByUserIdAndBlockedUserId(1L, 2L)).thenReturn(true);

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        blacklistService.addToBlacklist(1L, 2L);
                    }
                });

        assertEquals("已在黑名单中", error.getMessage());
    }

    @Test
    void addToBlacklistShouldSaveNewEntry() {
        when(blacklistRepository.existsByUserIdAndBlockedUserId(1L, 2L)).thenReturn(false);
        when(blacklistRepository.save(org.mockito.ArgumentMatchers.any(Blacklist.class)))
                .thenAnswer(new org.mockito.stubbing.Answer<Blacklist>() {
                    @Override
                    public Blacklist answer(org.mockito.invocation.InvocationOnMock invocation) {
                        return (Blacklist) invocation.getArgument(0);
                    }
                });

        Blacklist result = blacklistService.addToBlacklist(1L, 2L);

        assertEquals(Long.valueOf(1L), result.getUserId());
        assertEquals(Long.valueOf(2L), result.getBlockedUserId());
        assertNotNull(result.getCreatedAt());
    }

    @Test
    void getBlacklistShouldReturnRepositoryData() {
        Blacklist blacklist = new Blacklist();
        blacklist.setId(1L);
        List<Blacklist> list = Arrays.asList(blacklist);
        when(blacklistRepository.findByUserId(1L)).thenReturn(list);

        List<Blacklist> result = blacklistService.getBlacklist(1L);

        assertEquals(1, result.size());
    }

    @Test
    void removeFromBlacklistShouldDelegateToRepository() {
        blacklistService.removeFromBlacklist(1L, 2L);

        verify(blacklistRepository).deleteByUserIdAndBlockedUserId(1L, 2L);
    }
}
