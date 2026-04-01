package com.hailiao.common.repository;

import com.hailiao.common.entity.VideoCall;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VideoCallRepository extends JpaRepository<VideoCall, Long> {

    List<VideoCall> findByCallerIdOrderByCreatedAtDesc(Long callerId);

    List<VideoCall> findByCalleeIdOrderByCreatedAtDesc(Long calleeId);

    @Query("SELECT vc FROM VideoCall vc WHERE (vc.callerId = :userId OR vc.calleeId = :userId) ORDER BY vc.createdAt DESC")
    List<VideoCall> findByUserIdOrderByCreatedAtDesc(@Param("userId") Long userId);

    @Query("SELECT vc FROM VideoCall vc WHERE vc.status = :status AND (vc.callerId = :userId OR vc.calleeId = :userId)")
    List<VideoCall> findByStatusAndUserId(@Param("status") Integer status, @Param("userId") Long userId);

    Optional<VideoCall> findFirstByCallerIdAndCalleeIdAndStatusOrderByCreatedAtDesc(Long callerId, Long calleeId, Integer status);

    Optional<VideoCall> findFirstByGroupIdAndStatusOrderByCreatedAtDesc(Long groupId, Integer status);

    @Query("SELECT COUNT(vc) FROM VideoCall vc WHERE vc.callerId = :userId AND vc.status = 2")
    Long countSuccessfulCallsByCaller(@Param("userId") Long userId);

    @Query("SELECT SUM(vc.duration) FROM VideoCall vc WHERE vc.callerId = :userId AND vc.status = 2")
    Long sumDurationByCaller(@Param("userId") Long userId);
}
