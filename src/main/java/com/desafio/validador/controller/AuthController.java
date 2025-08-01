package com.desafio.validador.controller;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.annotation.PostConstruct;
import javax.crypto.SecretKey;
import java.util.Date;
import java.util.Map;

@RestController
@RequestMapping("/oauth")
public class AuthController {

        private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

        @Value("${CLIENT_ID}")
        private String clientId;

        @Value("${CLIENT_SECRET}")
        private String clientSecret;

        @Value("${JWT_SECRET}")
        private String jwtSecret;

        private SecretKey secretKey;

        @PostConstruct
        public void init() {
                this.secretKey = Keys.hmacShaKeyFor(jwtSecret.getBytes());
                logger.info("JWT Secret initialized with key length: {}", jwtSecret.length());
        }

        @PostMapping(value = "/token", produces = MediaType.APPLICATION_JSON_VALUE)
        public ResponseEntity<?> gerarToken(@RequestParam String grant_type,
                        @RequestParam String client_id,
                        @RequestParam String client_secret) {
                logger.info("Requisição recebida em /oauth/token com grant_type={}, client_id={}", grant_type,
                                client_id);

                try {
                        if ("client_credentials".equals(grant_type)
                                        && client_id.equals(this.clientId)
                                        && client_secret.equals(this.clientSecret)) {

                                String accessToken = Jwts.builder()
                                                .setSubject(client_id)
                                                .setIssuedAt(new Date())
                                                .setExpiration(new Date(System.currentTimeMillis() + 3600 * 1000)) // 1
                                                                                                                   // hora
                                                .signWith(secretKey, SignatureAlgorithm.HS256)
                                                .compact();

                                logger.info("Token JWT gerado com sucesso para o client_id={}", client_id);

                                return ResponseEntity.ok(Map.of(
                                                "access_token", accessToken,
                                                "token_type", "Bearer",
                                                "expires_in", 3600));
                        } else {
                                logger.warn("Credenciais inválidas recebidas para client_id={}", client_id);
                                return ResponseEntity
                                                .status(HttpStatus.UNAUTHORIZED)
                                                .body(Map.of("error", "Credenciais inválidas"));
                        }
                } catch (Exception e) {
                        logger.error("Erro inesperado ao gerar token para client_id={}. Detalhes: {}", client_id,
                                        e.getMessage(), e);
                        return ResponseEntity
                                        .status(HttpStatus.INTERNAL_SERVER_ERROR)
                                        .body(Map.of("error", "Erro interno ao gerar token"));
                }
        }

        @GetMapping("/health")
        public ResponseEntity<String> healthCheck() {
                logger.info("Health check chamado com sucesso.");
                return ResponseEntity.ok("OK");
        }
}
