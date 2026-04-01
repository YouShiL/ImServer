package com.hailiao.common.service;

import com.hailiao.common.entity.User;
import com.hailiao.common.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @Test
    void registerShouldRejectDuplicatePhone() {
        User user = new User();
        user.setPhone("13800138000");

        when(userRepository.existsByPhone("13800138000")).thenReturn(true);

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        userService.register(user);
                    }
                });

        assertEquals("手机号已注册", error.getMessage());
    }

    @Test
    void registerShouldApplyDefaultValues() {
        User user = new User();
        user.setPhone("13800138000");
        user.setPassword("123456");

        when(userRepository.existsByPhone("13800138000")).thenReturn(false);
        when(userRepository.existsByUserId(any(String.class))).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(new org.mockito.stubbing.Answer<User>() {
            @Override
            public User answer(org.mockito.invocation.InvocationOnMock invocation) {
                return (User) invocation.getArgument(0);
            }
        });

        User saved = userService.register(user);

        assertNotNull(saved.getUserId());
        assertTrue(encoder.matches("123456", saved.getPassword()));
        assertEquals(Integer.valueOf(0), saved.getOnlineStatus());
        assertTrue(saved.getShowOnlineStatus());
        assertTrue(saved.getShowLastOnline());
        assertTrue(saved.getAllowSearchByPhone());
        assertTrue(saved.getNeedFriendVerification());
        assertFalse(saved.getDeviceLock());
        assertEquals(Integer.valueOf(1), saved.getStatus());
        assertNotNull(saved.getCreatedAt());
    }

    @Test
    void validateLoginShouldRejectWrongPassword() {
        User user = new User();
        user.setPhone("13800138000");
        user.setPassword(encoder.encode("correct"));
        user.setStatus(1);

        when(userRepository.findByPhone("13800138000")).thenReturn(Optional.of(user));

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        userService.validateLogin("13800138000", "wrong");
                    }
                });

        assertEquals("密码错误", error.getMessage());
    }

    @Test
    void changePasswordShouldRejectWrongOldPassword() {
        User user = new User();
        user.setId(1L);
        user.setPassword(encoder.encode("old-pass"));

        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        RuntimeException error = assertThrows(RuntimeException.class,
                new org.junit.jupiter.api.function.Executable() {
                    @Override
                    public void execute() {
                        userService.changePassword(1L, "wrong-old", "new-pass");
                    }
                });

        assertEquals("原密码错误", error.getMessage());
    }

    @Test
    void updateOnlineStatusShouldSetLastOnlineWhenOffline() {
        User user = new User();
        user.setId(1L);
        user.setOnlineStatus(1);

        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        userService.updateOnlineStatus(1L, 0);

        assertEquals(Integer.valueOf(0), user.getOnlineStatus());
        assertNotNull(user.getLastOnlineAt());
        verify(userRepository).save(user);
    }
}
