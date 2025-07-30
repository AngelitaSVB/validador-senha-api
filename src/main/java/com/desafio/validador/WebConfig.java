// src/main/java/com/desafio/validador/config/WebConfig.java
package com.desafio.validador.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration // Indica que esta classe é uma fonte de definições de beans para o contexto da aplicação
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**") // Aplica a TODOS os endpoints da sua API
                .allowedOrigins(
                        "http://localhost:4200", // Origem do seu ambiente de desenvolvimento local
                        "http://validador-dev-placeholder.s3-website-sa-east-1.amazonaws.com" // Origem do seu ambiente de produção/dev hospedado
                )
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS") // Permite esses métodos HTTP
                .allowedHeaders("*") // Permite todos os cabeçalhos nas requisições (Content-Type, Authorization, etc.)
                .allowCredentials(true); // Permite o envio de credenciais (cookies, headers de autenticação)
    }
}