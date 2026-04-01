package com.hailiao.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@ComponentScan(basePackages = {"com.hailiao.api", "com.hailiao.common"})
@EntityScan(basePackages = "com.hailiao.common.entity")
@EnableJpaRepositories(basePackages = "com.hailiao.common.repository")
public class HailiaoApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(HailiaoApiApplication.class, args);
    }
}