package com.hailiao.common.repository;

import com.hailiao.common.entity.GroupMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Date;
import java.util.List;
import java.util.Optional;

@Repository
public interface GroupMemberRepository extends JpaRepository<GroupMember, Long> {
    List<GroupMember> findByGroupId(Long groupId);
    List<GroupMember> findByUserId(Long userId);
    Optional<GroupMember> findByGroupIdAndUserId(Long groupId, Long userId);
    List<GroupMember> findByGroupIdAndRole(Long groupId, Integer role);
    long countByGroupId(Long groupId);
    long countByUserId(Long userId);
    
    @Query("SELECT gm FROM GroupMember gm WHERE gm.groupId = :groupId AND gm.role IN (1, 2)")
    List<GroupMember> findAdminsByGroupId(@Param("groupId") Long groupId);
    
    @Query("SELECT gm FROM GroupMember gm WHERE gm.groupId = :groupId AND gm.role = 1")
    List<GroupMember> findOwnersByGroupId(@Param("groupId") Long groupId);
    
    boolean existsByGroupIdAndUserId(Long groupId, Long userId);
    
    @Modifying
    @Query("DELETE FROM GroupMember gm WHERE gm.groupId = :groupId AND gm.userId = :userId")
    void deleteByGroupIdAndUserId(@Param("groupId") Long groupId, @Param("userId") Long userId);
    
    @Modifying
    @Query("UPDATE GroupMember gm SET gm.role = :role WHERE gm.groupId = :groupId AND gm.userId = :userId")
    void updateRole(@Param("groupId") Long groupId, @Param("userId") Long userId, @Param("role") Integer role);
    
    @Modifying
    @Query("UPDATE GroupMember gm SET gm.isMute = :mute, gm.muteUntil = :muteUntil WHERE gm.groupId = :groupId AND gm.userId = :userId")
    void updateMuteStatus(@Param("groupId") Long groupId, @Param("userId") Long userId, 
                          @Param("mute") Boolean mute, @Param("muteUntil") Date muteUntil);
    
    @Modifying
    @Query("UPDATE GroupMember gm SET gm.lastReadMsgId = :msgId WHERE gm.groupId = :groupId AND gm.userId = :userId")
    void updateLastReadMsgId(@Param("groupId") Long groupId, @Param("userId") Long userId, @Param("msgId") Long msgId);
}
