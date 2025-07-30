package com.desafio.validador.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig {

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                // Libera CORS para ambos os endpoints
                registry.addMapping("/api/**")
                        .allowedOrigins(
                            "http://localhost:4200",
                            "https://validador-dev-placeholder.s3-website-sa-east-1.amazonaws.com")
                        .allowedMethods("POST", "OPTIONS")
                        .allowedHeaders("*");

                registry.addMapping("/oauth/**")
                        .allowedOrigins(
                            "http://localhost:4200",
                            "https://validador-dev-placeholder.s3-website-sa-east-1.amazonaws.com")
                        .allowedMethods("POST", "OPTIONS")
                        .allowedHeaders("*");
            }
        };
    }
}
