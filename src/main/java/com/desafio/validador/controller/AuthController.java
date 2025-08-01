package com.desafio.validador.controller;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.annotation.PostConstruct;
import javax.crypto.SecretKey;
import java.util.Date;
import java.util.Map;

@RestController
@RequestMapping("/oauth")
public class AuthController {

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
        }

        @PostMapping("/token")
        public ResponseEntity<?> gerarToken(
                        @RequestParam String grant_type,
                        @RequestParam String client_id,
                        @RequestParam String client_secret) {

                if ("client_credentials".equals(grant_type)
                                && client_id.equals(clientId)
                                && client_secret.equals(clientSecret)) {

                        String jwt = Jwts.builder()
                                        .setSubject(client_id)
                                        .setIssuedAt(new Date())
                                        .setExpiration(new Date(System.currentTimeMillis() + 3600000)) // 1h
                                        .signWith(secretKey, SignatureAlgorithm.HS256)
                                        .compact();

                        return ResponseEntity.ok(Map.of(
                                        "access_token", jwt,
                                        "token_type", "Bearer",
                                        "expires_in", "3600"));
                } else {
                        return ResponseEntity.status(401).body("Credenciais inválidas");
                }
        }

        @GetMapping("/health")
        public ResponseEntity<String> healthCheck() {
                return ResponseEntity.ok("OK");
        }
}
