package com.desafio.validador.controller;

import com.desafio.validador.model.PasswordRequest;
import com.desafio.validador.model.PasswordResponse;
import com.desafio.validador.service.PasswordService;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class PasswordController {

    private final PasswordService passwordService;

    @Value("${JWT_SECRET}")
    private String jwtSecret;

    private SecretKey secretKey;

    public PasswordController(PasswordService passwordService) {
        this.passwordService = passwordService;
    }

    @PostConstruct
    public void initSecretKey() {
        this.secretKey = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
    }

    @PostMapping("/validar")
    public ResponseEntity<?> validarSenha(
            @RequestHeader(HttpHeaders.AUTHORIZATION) String authorization,
            @RequestBody PasswordRequest request) {

        try {
            if (authorization == null || !authorization.startsWith("Bearer ")) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("erro", "Token ausente ou inválido"));
            }

            String token = authorization.substring(7); // Remove "Bearer "

            // Apenas valida o token, sem guardar o resultado
            Jwts.parserBuilder()
                    .setSigningKey(secretKey)
                    .build()
                    .parseClaimsJws(token);

            PasswordResponse response = passwordService.validarSenha(request.getSenha());
            return ResponseEntity.ok(response);

        } catch (JwtException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("erro", "Token inválido ou expirado"));
        }
    }
}
