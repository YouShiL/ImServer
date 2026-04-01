package com.hailiao.admin;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@ComponentScan(basePackages = {"com.hailiao.admin", "com.hailiao.common"})
@EntityScan(basePackages = "com.hailiao.common.entity")
@EnableJpaRepositories(basePackages = "com.hailiao.common.repository")
public class HailiaoAdminApplication {
    public static void main(String[] args) {
        SpringApplication.run(HailiaoAdminApplication.class, args);
    }
}