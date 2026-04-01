package com.hailiao.api;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertNotNull;

class HailiaoApiApplicationSmokeTest {

    @Test
    void applicationEntryPointIsPresent() {
        assertNotNull(HailiaoApiApplication.class);
    }
}
