package com.hailiao.common.service;

import com.hailiao.common.entity.User;
import com.hailiao.common.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.Random;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Transactional
    public User register(User user) {
        if (userRepository.existsByPhone(user.getPhone())) {
            throw new RuntimeException("手机号已注册");
        }

        user.setUserId(generateUserId());
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        user.setNickname(user.getNickname() != null ? user.getNickname() : "用户" + user.getUserId());
        user.setAvatar("");
        user.setGender(0);
        user.setOnlineStatus(0);
        user.setShowOnlineStatus(true);
        user.setShowLastOnline(true);
        user.setAllowSearchByPhone(true);
        user.setNeedFriendVerification(true);
        user.setIsVip(false);
        user.setIsPrettyNumber(false);
        user.setFriendLimit(500);
        user.setGroupLimit(10);
        user.setGroupMemberLimit(500);
        user.setDeviceLock(false);
        user.setStatus(1);
        user.setCreatedAt(new Date());
        user.setUpdatedAt(new Date());

        return userRepository.save(user);
    }

    public User login(String phone, String password) {
        User user = validateLogin(phone, password);
        user.setLastLoginAt(new Date());
        user.setOnlineStatus(1);
        return userRepository.save(user);
    }

    public User validateLogin(String phone, String password) {
        Optional<User> userOpt = userRepository.findByPhone(phone);
        if (!userOpt.isPresent()) {
            throw new RuntimeException("用户不存在");
        }

        User user = userOpt.get();
        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new RuntimeException("密码错误");
        }

        if (user.getStatus() == 0) {
            throw new RuntimeException("账号已被禁用");
        }

        return user;
    }

    @Transactional
    public User markLoginSuccess(Long userId, String loginIp) {
        User user = getUserById(userId);
        user.setLastLoginAt(new Date());
        user.setLastLoginIp(loginIp);
        user.setOnlineStatus(1);
        user.setUpdatedAt(new Date());
        return userRepository.save(user);
    }

    public User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("用户不存在"));
    }

    public User getUserByUserId(String userId) {
        return userRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));
    }

    public User getUserByPhone(String phone) {
        return userRepository.findByPhone(phone)
                .orElseThrow(() -> new RuntimeException("用户不存在"));
    }

    @Transactional
    public User updateUser(User user) {
        User existingUser = getUserById(user.getId());

        if (user.getNickname() != null) {
            existingUser.setNickname(user.getNickname());
        }
        if (user.getAvatar() != null) {
            existingUser.setAvatar(user.getAvatar());
        }
        if (user.getGender() != null) {
            existingUser.setGender(user.getGender());
        }
        if (user.getRegion() != null) {
            existingUser.setRegion(user.getRegion());
        }
        if (user.getSignature() != null) {
            existingUser.setSignature(user.getSignature());
        }
        if (user.getBackground() != null) {
            existingUser.setBackground(user.getBackground());
        }
        if (user.getShowOnlineStatus() != null) {
            existingUser.setShowOnlineStatus(user.getShowOnlineStatus());
        }
        if (user.getShowLastOnline() != null) {
            existingUser.setShowLastOnline(user.getShowLastOnline());
        }
        if (user.getAllowSearchByPhone() != null) {
            existingUser.setAllowSearchByPhone(user.getAllowSearchByPhone());
        }
        if (user.getNeedFriendVerification() != null) {
            existingUser.setNeedFriendVerification(user.getNeedFriendVerification());
        }
        if (user.getDeviceLock() != null) {
            existingUser.setDeviceLock(user.getDeviceLock());
        }

        existingUser.setUpdatedAt(new Date());
        return userRepository.save(existingUser);
    }

    @Transactional
    public void changePassword(Long userId, String oldPassword, String newPassword) {
        User user = getUserById(userId);
        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            throw new RuntimeException("原密码错误");
        }
        user.setPassword(passwordEncoder.encode(newPassword));
        user.setUpdatedAt(new Date());
        userRepository.save(user);
    }

    @Transactional
    public void updateOnlineStatus(Long userId, Integer status) {
        User user = getUserById(userId);
        user.setOnlineStatus(status);
        if (status != null && status == 0) {
            user.setLastOnlineAt(new Date());
        }
        user.setUpdatedAt(new Date());
        userRepository.save(user);
    }

    public Page<User> getUserList(String keyword, Integer status, Pageable pageable) {
        Specification<User> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (keyword != null && !keyword.isEmpty()) {
                predicates.add(cb.or(
                        cb.like(root.get("userId"), "%" + keyword + "%"),
                        cb.like(root.get("phone"), "%" + keyword + "%"),
                        cb.like(root.get("nickname"), "%" + keyword + "%")
                ));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return userRepository.findAll(spec, pageable);
    }

    public long getTotalUserCount() {
        return userRepository.count();
    }

    public long getActiveUserCount() {
        return userRepository.countByStatus(1);
    }

    @Transactional
    public void banUser(Long userId, String reason) {
        User user = getUserById(userId);
        user.setStatus(0);
        user.setUpdatedAt(new Date());
        userRepository.save(user);
    }

    @Transactional
    public void unbanUser(Long userId) {
        User user = getUserById(userId);
        user.setStatus(1);
        user.setUpdatedAt(new Date());
        userRepository.save(user);
    }

    @Transactional
    public void deleteUser(Long userId) {
        User user = getUserById(userId);
        userRepository.delete(user);
    }

    private String generateUserId() {
        Random random = new Random();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 10; i++) {
            sb.append(random.nextInt(10));
        }
        String userId = sb.toString();

        if (userRepository.existsByUserId(userId)) {
            return generateUserId();
        }

        return userId;
    }
}
