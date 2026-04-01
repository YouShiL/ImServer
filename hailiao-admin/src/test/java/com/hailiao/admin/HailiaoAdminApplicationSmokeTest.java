package com.hailiao.admin;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertNotNull;

class HailiaoAdminApplicationSmokeTest {

    @Test
    void applicationEntryPointIsPresent() {
        assertNotNull(HailiaoAdminApplication.class);
    }
}
