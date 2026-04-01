package com.hailiao.common.service;

import com.hailiao.common.entity.PrettyNumber;
import com.hailiao.common.repository.PrettyNumberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PrettyNumberServiceTest {

    @Mock
    private PrettyNumberRepository prettyNumberRepository;

    @InjectMocks
    private PrettyNumberService prettyNumberService;

    @Test
    void createPrettyNumberShouldRejectDuplicateNumber() {
        when(prettyNumberRepository.findByNumber("888888")).thenReturn(Optional.of(new PrettyNumber()));

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        prettyNumberService.createPrettyNumber("888888", 3, new BigDecimal("999.00"));
                    }
                });

        assertEquals("\u9753\u53f7\u5df2\u5b58\u5728", error.getMessage());
    }

    @Test
    void buyPrettyNumberShouldMarkAsSold() {
        PrettyNumber prettyNumber = new PrettyNumber();
        prettyNumber.setId(1L);
        prettyNumber.setStatus(0);

        when(prettyNumberRepository.findById(1L)).thenReturn(Optional.of(prettyNumber));
        when(prettyNumberRepository.save(any(PrettyNumber.class))).thenAnswer(new org.mockito.stubbing.Answer<PrettyNumber>() {
            @Override
            public PrettyNumber answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (PrettyNumber) invocation.getArgument(0);
            }
        });

        PrettyNumber saved = prettyNumberService.buyPrettyNumber(1L, 9L);

        assertEquals(Integer.valueOf(1), saved.getStatus());
        assertEquals(Long.valueOf(9L), saved.getUserId());
        assertNotNull(saved.getBuyTime());
    }

    @Test
    void releasePrettyNumberShouldResetOwner() {
        PrettyNumber prettyNumber = new PrettyNumber();
        prettyNumber.setId(1L);
        prettyNumber.setStatus(1);
        prettyNumber.setUserId(9L);

        when(prettyNumberRepository.findById(1L)).thenReturn(Optional.of(prettyNumber));

        prettyNumberService.releasePrettyNumber(1L);

        assertEquals(Integer.valueOf(0), prettyNumber.getStatus());
        assertEquals(null, prettyNumber.getUserId());
        assertEquals(null, prettyNumber.getBuyTime());
    }
}
