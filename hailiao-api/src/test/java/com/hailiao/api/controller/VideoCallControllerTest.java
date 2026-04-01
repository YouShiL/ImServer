package com.hailiao.api.controller;

import com.hailiao.api.dto.ResponseDTO;
import com.hailiao.common.entity.VideoCall;
import com.hailiao.common.service.VideoCallService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VideoCallControllerTest {

    @Mock
    private VideoCallService videoCallService;

    @InjectMocks
    private VideoCallController videoCallController;

    @Test
    void initiateCallShouldReturnCreatedCall() {
        VideoCall call = buildCall(1L);
        when(videoCallService.initiateCall(1L, 2L, null, 2)).thenReturn(call);

        ResponseEntity<ResponseDTO<VideoCall>> response = videoCallController.initiateCall(1L, 2L, null, 2);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(Long.valueOf(1L), response.getBody().getData().getId());
    }

    @Test
    void acceptCallShouldDelegateToService() {
        VideoCall call = buildCall(2L);
        when(videoCallService.acceptCall(2L, 2L)).thenReturn(call);

        ResponseEntity<ResponseDTO<VideoCall>> response = videoCallController.acceptCall(2L, 2L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(videoCallService).acceptCall(2L, 2L);
    }

    @Test
    void getCallByIdShouldReturnNotFoundWhenMissing() {
        when(videoCallService.getCallById(9L)).thenReturn(Optional.<VideoCall>empty());

        ResponseEntity<ResponseDTO<VideoCall>> response = videoCallController.getCallById(9L);

        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
    }

    @Test
    void getCallStatisticsShouldReturnServiceData() {
        Map<String, Object> stats = new HashMap<String, Object>();
        stats.put("totalCalls", 3L);

        when(videoCallService.getCallStatistics(1L)).thenReturn(stats);

        ResponseEntity<ResponseDTO<Map<String, Object>>> response = videoCallController.getCallStatistics(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(stats, response.getBody().getData());
    }

    @Test
    void sendSignalShouldDelegateToService() {
        Map<String, Object> signalData = new HashMap<String, Object>();
        signalData.put("sdp", "offer");

        ResponseEntity<ResponseDTO<Void>> response =
                videoCallController.sendSignal(1L, 2L, "offer", signalData);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(videoCallService).handleWebRTCSignal(1L, 2L, "offer", signalData);
    }

    private VideoCall buildCall(Long id) {
        VideoCall call = new VideoCall();
        call.setId(id);
        call.setCallerId(1L);
        call.setCalleeId(2L);
        call.setCallType(2);
        call.setStatus(1);
        call.setStartTime(LocalDateTime.now());
        return call;
    }
}
